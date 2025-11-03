//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus
import CoreTextSwift
import STTextViewCommon

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
                // estimate max gutter width
                gutterView.frame.origin = .zero
                gutterView.frame.size.width = max(gutterView.minimumThickness, CGFloat(textContentManager.length) / (1024 * 100))
                gutterView.frame.size.height = contentView.bounds.height
                gutterView.textColor = textColor.withAlphaComponent(0.45)
                gutterView.selectedLineTextColor = textColor
                gutterView.highlightSelectedLine = highlightSelectedLine
                gutterView.selectedLineHighlightColor = selectedLineHighlightColor
                gutterView.backgroundColor = backgroundColor
                if let enclosingScrollView {
                    enclosingScrollView.addFloatingSubview(gutterView, for: .horizontal)
                } else {
                    self.addSubview(gutterView)
                }
                self.gutterView = gutterView
                needsLayout = true
                layoutGutter()
            } else if newValue == false, let gutterView {
                gutterView.removeFromSuperview()
                self.gutterView = nil
                needsLayout = true
                layoutGutter()
            }
        }
        get {
            gutterView != nil
        }
    }

    internal func layoutGutter() {
        guard let gutterView, textLayoutManager.textViewportLayoutController.viewportRange != nil else {
            return
        }

        gutterView.frame.size.height = contentView.bounds.height

        layoutGutterLineNumbers()
        layoutGutterMarkers()
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
            .foregroundColor: gutterView.textColor
        ]

        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (gutterView.selectedLineTextColor ?? gutterView.textColor).cgColor
        ]

        // if empty document
        if textLayoutManager.documentRange.isEmpty {
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                let lineNumber = 1

                // Use typingAttributes to calculate baseline position for empty document.
                // The cell is sized for typingLineHeight, so baseline calculation should use typing font metrics
                // to match where text baseline would be. Line number is still drawn with gutter font.
                let ctNumberLine = CTLineCreateWithAttributedString(NSAttributedString(string: "\(lineNumber)", attributes: typingAttributes))
                let baselineParagraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? defaultParagraphStyle
                let baselineOffset = -(ctNumberLine.typographicHeight() * (baselineParagraphStyle.stLineHeightMultiple - 1.0) / 2)

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
                        x: 0,
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
            // Get visible fragment views from the map and sort by vertical position
            let visibleFragmentViews = (fragmentViewMap.keyEnumerator().allObjects as! [NSTextLayoutFragment])
                .compactMap { layoutFragment -> (NSTextLayoutFragment, STTextLayoutFragmentView)? in
                    guard let fragmentView = fragmentViewMap.object(forKey: layoutFragment),
                          layoutFragment.rangeInElement.intersects(viewportRange)
                    else {
                        return nil
                    }
                    return (layoutFragment, fragmentView)
                }
                .sorted { $0.1.frame.origin.y < $1.1.frame.origin.y }

            guard !visibleFragmentViews.isEmpty else {
                return
            }

            // Calculate line number offset based on document position
            let textElements = textContentManager.textElements(
                for: NSTextRange(
                    location: textLayoutManager.documentRange.location,
                    end: viewportRange.location
                )!
            )

            var requiredWidthFitText = gutterView.minimumThickness
            let startLineIndex = textElements.count
            var linesCount = 0

            for (layoutFragment, fragmentView) in visibleFragmentViews {
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

                for textLineFragment in layoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == textLineFragment) {
                    let isLineSelected = STGutterCalculations.isLineSelected(
                        textLineFragment: textLineFragment,
                        layoutFragment: layoutFragment,
                        contentRangeInElement: contentRangeInElement,
                        textLayoutManager: textLayoutManager
                    )
                    let lineNumber = startLineIndex + linesCount + 1

                    // Calculate baseline offset based on paragraph style
                    var baselineYOffset: CGFloat = 0
                    let locationForFirstCharacter: CGPoint
                    let cellFrame: CGRect

                    if layoutFragment.isExtraLineFragment {
                        locationForFirstCharacter = STGutterCalculations.locationForFirstCharacter(
                            in: layoutFragment,
                            textLineFragment: textLineFragment,
                            isExtraTextLineFragment: textLineFragment.isExtraLineFragment
                        )

                        if let paragraphStyle = STGutterCalculations.paragraphStyleForBaseline(
                            in: layoutFragment,
                            textLineFragment: textLineFragment,
                            isExtraTextLineFragment: textLineFragment.isExtraLineFragment
                        ) {
                            let lineHeight = textLineFragment.isExtraLineFragment
                                ? layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2].typographicBounds.height
                                : textLineFragment.typographicBounds.height
                            baselineYOffset = STGutterCalculations.calculateBaselineOffset(
                                lineHeight: lineHeight,
                                paragraphStyle: paragraphStyle
                            )
                        }

                        // Use fragment view's actual frame for positioning
                        let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                        cellFrame = CGRect(
                            origin: CGPoint(
                                x: fragmentView.frame.origin.x + prevTextLineFragment.typographicBounds.origin.x,
                                y: fragmentView.frame.origin.y + prevTextLineFragment.typographicBounds.maxY
                            ),
                            size: CGSize(
                                width: fragmentView.frame.width,
                                height: prevTextLineFragment.typographicBounds.height
                            )
                        )
                    } else {
                        locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)

                        if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                            baselineYOffset = STGutterCalculations.calculateBaselineOffset(
                                lineHeight: textLineFragment.typographicBounds.height,
                                paragraphStyle: paragraphStyle
                            )
                        }

                        // Use fragment view's actual frame for positioning
                        cellFrame = CGRect(
                            origin: CGPoint(
                                x: fragmentView.frame.origin.x + textLineFragment.typographicBounds.origin.x,
                                y: fragmentView.frame.origin.y + textLineFragment.typographicBounds.origin.y
                            ),
                            size: CGSize(
                                width: fragmentView.frame.width,
                                height: fragmentView.frame.height
                            )
                        )
                    }

                    var effectiveLineTextAttributes = lineTextAttributes
                    if gutterView.highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                        effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                    }

                    if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                        effectiveLineTextAttributes[.paragraphStyle] = paragraphStyle
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
                            x: 0,
                            y: cellFrame.origin.y
                        ),
                        size: CGSize(
                            width: max(cellFrame.intersection(gutterView.containerView.frame).width, gutterView.containerView.frame.width),
                            height: cellFrame.size.height
                        )
                    ).pixelAligned

                    gutterView.containerView.addSubview(numberCell)
                    requiredWidthFitText = max(requiredWidthFitText, numberCell.intrinsicContentSize.width)
                    linesCount += 1
                }
            }

            // FIXME: gutter width change affects contentView frame (in setFrameSize) layout that affects viewport layout
            // (I'm being vague because I don't understand how).
            // When viewport goes being the bounds, gutter width back to minimumThickness that breaks layout because
            // one more layoutViewport() clear out the fragment cache used to restore viewport location
            // TODO: gutter width should not adjust while scrolling/layout. It should adjust on content change.

            // adjust ruleThickness to fit the text based on last numberView
            // if textLayoutManager.textViewportLayoutController.viewportRange != nil {
            //     let newGutterWidth = max(requiredWidthFitText, gutterView.minimumThickness)
            //     if !newGutterWidth.isAlmostEqual(to: gutterView.frame.size.width) {
            //         gutterView.frame.size.width = newGutterWidth
            //     }
            // }
        }
    }

    private func layoutGutterMarkers() {
        guard let gutterView else {
            return
        }

        gutterView.layoutMarkers()
    }
}
