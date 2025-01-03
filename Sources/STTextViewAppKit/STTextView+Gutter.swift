//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus
import CoreTextSwift

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    @objc public func toggleRuler(_ sender: Any?) {
        isGutterVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    internal var isGutterVisible: Bool {
        set {
            if gutterView == nil, newValue == true {
                let gutterView = STGutterView()
                gutterView.frame.size.width = gutterView.minimumThickness
                gutterView.selectedLineTextColor = textColor
                gutterView.highlightSelectedLine = highlightSelectedLine
                gutterView.selectedLineHighlightColor = selectedLineHighlightColor
                if let scrollView {
                    scrollView.addSubview(gutterView, positioned: .below, relativeTo: scrollView.horizontalScroller)
                }
                self.gutterView = gutterView
                needsLayout = true
            } else if newValue == false {
                if let gutterView {
                    gutterView.removeFromSuperview()
                    self.gutterView = nil
                    needsLayout = true
                }
            }
            layoutGutter()
        }
        get {
            gutterView != nil
        }
    }

    internal func layoutGutter() {
        if let gutterView {
            var origin = frame.origin
            var height = contentView.visibleRect.height
            if let scrollView {
                origin.y = origin.y + scrollView.contentInsets.top
                height = scrollView.documentVisibleRect.height - scrollView.contentInsets.top
            }
            gutterView.frame.origin = origin
            gutterView.frame.size.height = height
            layoutGutterLineNumbers()
            layoutGutterMarkers()
        }
    }

    private func layoutGutterLineNumbers() {
        guard let gutterView, let scrollView else {
            return
        }

        gutterView.containerView.subviews.compactMap {
            $0 as? STGutterLineNumberCell
        }.forEach {
            $0.removeFromSuperviewWithoutNeedingDisplay()
        }

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: gutterView.font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (gutterView.selectedLineTextColor ?? gutterView.textColor).cgColor
        ]

        // if empty document
        if textLayoutManager.documentRange.isEmpty {
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                let lineNumber = 1

                // Use typingAttributes because there's no content so we made up "1" with typing attributes
                // that allow us to calculate baseline position.
                // Calculations in sync with position used by STTextLayoutFragment
                let ctNumberLine = CTLineCreateWithAttributedString(NSAttributedString(string: "\(lineNumber)", attributes: lineTextAttributes))
                let baselineParagraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? defaultParagraphStyle
                let baselineOffset = -(ctNumberLine.typographicHeight() * (baselineParagraphStyle.lineHeightMultiple - 1.0) / 2)

                var effectiveLineTextAttributes = lineTextAttributes
                if gutterView.highlightSelectedLine/*, isLineSelected*/, !selectedLineTextAttributes.isEmpty {
                    effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                }

                let numberCell = STGutterLineNumberCell(
                    firstBaseline: ctNumberLine.typographicBounds().ascent - baselineOffset,
                    attributes: effectiveLineTextAttributes,
                    number: lineNumber
                )

                numberCell.insets = gutterView.insets

                if gutterView.highlightSelectedLine, textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty, !textLayoutManager.insertionPointSelections.isEmpty {
                    numberCell.layer?.backgroundColor = gutterView.selectedLineHighlightColor.cgColor
                }

                numberCell.frame = CGRect(
                    origin: CGPoint(
                        x: bounds.minX,
                        y: selectionFrame.origin.y - scrollView.contentView.bounds.minY - scrollView.contentInsets.top
                    ),
                    size: CGSize(
                        width: gutterView.containerView.frame.width,
                        height: typingLineHeight
                    )
                ).pixelAligned

                gutterView.containerView.addSubview(numberCell)
            }
        } else if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {

            let textElements = textContentManager.textElements(
                for: NSTextRange(
                    location: textLayoutManager.documentRange.location,
                    end: viewportRange.location
                )!
            )

            // if not empty document
            var requiredWidthFitText = gutterView.minimumThickness
            let startLineIndex = textElements.count
            var linesCount = 0
            textLayoutManager.enumerateTextLayoutFragments(in: viewportRange, options: .ensuresLayout) { layoutFragment in
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

                for textLineFragment in layoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == textLineFragment) {
                    func isLineSelected() -> Bool {
                        textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
                            var result = true
                            if textLineFragment.isExtraLineFragment {
                                let c1 = layoutFragment.rangeInElement.endLocation == selectionTextRange.location
                                result = result && c1
                            } else {
                                let c1 = contentRangeInElement.contains(selectionTextRange)
                                let c2 = contentRangeInElement.intersects(selectionTextRange)
                                let c3 = selectionTextRange.contains(contentRangeInElement)
                                let c4 = selectionTextRange.intersects(contentRangeInElement)
                                let c5 = contentRangeInElement.endLocation == selectionTextRange.location
                                result = result && (c1 || c2 || c3 || c4 || c5)
                            }
                            return partialResult && result
                        }
                    }

                    let isLineSelected = isLineSelected()
                    let lineNumber = startLineIndex + linesCount + 1

                    // calculated values depends on the "isExtraLineFragment" condition
                    var baselineYOffset: CGFloat = 0
                    let locationForFirstCharacter: CGPoint
                    let lineFragmentFrame: CGRect

                    // The logic for extra line handling would use some cleanup
                    // It apply workaround for FB15131180 invalid frame being reported
                    // for the extra line fragment. The workaround is to calculate (adjust)
                    // extra line fragment frame based on previous text line (from the same layout fragment)
                    if layoutFragment.isExtraLineFragment {
                        if !textLineFragment.isExtraLineFragment {
                            locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)

                            if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                                baselineYOffset = -(textLineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                            }

                            lineFragmentFrame = CGRect(
                                origin: CGPoint(
                                    x: layoutFragment.layoutFragmentFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                                    y: layoutFragment.layoutFragmentFrame.origin.y + textLineFragment.typographicBounds.origin.y - scrollView.contentView.bounds.minY - scrollView.contentInsets.top
                                ),
                                size: CGSize(
                                    width: textLineFragment.typographicBounds.width,
                                    height: textLineFragment.typographicBounds.height
                                )
                            )
                        } else {
                            // Use values from the same layoutFragment but previous line, that is not extra line fragment.
                            // Since this is extra line fragment, it is guaranteed that there is at least 2 line fragments in the layout fragment
                            let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                            locationForFirstCharacter = prevTextLineFragment.locationForCharacter(at: 0)

                            if let paragraphStyle = prevTextLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                                baselineYOffset = -(prevTextLineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                            }

                            lineFragmentFrame = CGRect(
                                origin: CGPoint(
                                    x: layoutFragment.layoutFragmentFrame.origin.x + prevTextLineFragment.typographicBounds.origin.x,
                                    y: layoutFragment.layoutFragmentFrame.origin.y + prevTextLineFragment.typographicBounds.maxY - scrollView.contentView.bounds.minY - scrollView.contentInsets.top
                                ),
                                size: CGSize(
                                    width: textLineFragment.typographicBounds.width,
                                    height: prevTextLineFragment.typographicBounds.height
                                )
                            )
                        }
                    } else {
                        locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)

                        if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                            baselineYOffset = -(textLineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                        }

                        lineFragmentFrame = CGRect(
                            origin: CGPoint(
                                x: layoutFragment.layoutFragmentFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                                y: layoutFragment.layoutFragmentFrame.origin.y + textLineFragment.typographicBounds.origin.y - scrollView.contentView.bounds.minY - scrollView.contentInsets.top
                            ),
                            size: CGSize(
                                width: layoutFragment.layoutFragmentFrame.width, // extend width to he fragment layout for the convenience of gutter
                                height: layoutFragment.layoutFragmentFrame.height
                            )
                        )
                    }

                    var effectiveLineTextAttributes = lineTextAttributes
                    if gutterView.highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                        effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                    }

                    let numberCell = STGutterLineNumberCell(
                        firstBaseline: locationForFirstCharacter.y + baselineYOffset,
                        attributes: effectiveLineTextAttributes,
                        number: lineNumber
                    )

                    numberCell.insets = gutterView.insets

                    if gutterView.highlightSelectedLine, isLineSelected, textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty, !textLayoutManager.insertionPointSelections.isEmpty {
                        numberCell.layer?.backgroundColor = gutterView.selectedLineHighlightColor.cgColor
                    }

                    numberCell.frame = CGRect(
                        origin: CGPoint(
                            x: bounds.minX,
                            y: lineFragmentFrame.origin.y
                        ),
                        size: CGSize(
                            width: max(lineFragmentFrame.intersection(gutterView.containerView.frame).width, gutterView.containerView.frame.width),
                            height: lineFragmentFrame.size.height
                        )
                    ).pixelAligned

                    gutterView.containerView.addSubview(numberCell)
                    requiredWidthFitText = max(requiredWidthFitText, numberCell.intrinsicContentSize.width)
                    linesCount += 1
                }

                return true
            }

            // adjust ruleThickness to fit the text based on last numberView
            let newGutterWidth = max(requiredWidthFitText, gutterView.minimumThickness)
            if !newGutterWidth.isAlmostEqual(to: gutterView.frame.size.width) {
                gutterView.frame.size.width = newGutterWidth
            }
        }
    }

    private func layoutGutterMarkers() {
        guard let gutterView else {
            return
        }

        gutterView.layoutMarkers()
    }
}
