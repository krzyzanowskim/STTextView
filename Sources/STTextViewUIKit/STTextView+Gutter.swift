//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus
import CoreTextSwift
import STTextViewCommon

extension STTextView {

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
                self.addSubview(gutterView)
                self.gutterView = gutterView
                setNeedsLayout()
            } else if newValue == false {
                if let gutterView {
                    gutterView.removeFromSuperview()
                    self.gutterView = nil
                    setNeedsLayout()
                }
            }
            layoutGutter()
        }
        get {
            gutterView != nil
        }
    }

    internal func layoutGutter() {
        guard let gutterView, textLayoutManager.textViewportLayoutController.viewportRange != nil else {
            return
        }

        // Coordinate system strategy:
        // UIKit lacks AppKit's addFloatingSubview mechanism, so we manually position
        // the gutter view using contentOffset to keep it visible during scrolling.
        // Cell Y coordinates compensate by subtracting contentOffset.y to remain
        // relative to the text layout coordinate space.
        gutterView.frame.origin.x = contentOffset.x
        gutterView.frame.origin.y = contentOffset.y
        gutterView.frame.size.height = contentView.frame.height

        layoutGutterLineNumbers()
        layoutGutterMarkers()
    }

    private func layoutGutterLineNumbers() {
        guard let gutterView else {
            return
        }

        gutterView.containerView.subviews.compactMap {
            $0 as? STGutterLineNumberCell
        }.forEach {
            $0.removeFromSuperview()
        }

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: gutterView.font,
            .foregroundColor: gutterView.textColor.cgColor
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
                if gutterView.highlightSelectedLine, !selectedLineTextAttributes.isEmpty {
                    effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                }

                let numberCell = STGutterLineNumberCell(
                    firstBaseline: ctNumberLine.typographicBounds().ascent - baselineOffset,
                    attributes: effectiveLineTextAttributes,
                    number: lineNumber
                )

                numberCell.insets = gutterView.insets

                if gutterView.highlightSelectedLine, textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty, !textLayoutManager.insertionPointSelections.isEmpty {
                    numberCell.backgroundColor = gutterView.selectedLineHighlightColor
                }

                numberCell.frame = CGRect(
                    origin: CGPoint(
                        x: 0,
                        y: selectionFrame.origin.y - contentOffset.y
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

            var requiredWidthFitText = gutterView.minimumThickness
            let startLineIndex = textElements.count
            var linesCount = 0
            textLayoutManager.enumerateTextLayoutFragments(in: viewportRange) { layoutFragment in
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

                for textLineFragment in layoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == textLineFragment) {
                    let isLineSelected = STGutterCalculations.isLineSelected(
                        textLineFragment: textLineFragment,
                        layoutFragment: layoutFragment,
                        contentRangeInElement: contentRangeInElement,
                        textLayoutManager: textLayoutManager
                    )

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

                        // Don't use fragment view for extra line fragments - use calculated frame
                        let rawFrame = STGutterCalculations.calculateExtraLineFragmentFrame(
                            layoutFragment: layoutFragment,
                            textLineFragment: textLineFragment,
                            isExtraTextLineFragment: textLineFragment.isExtraLineFragment
                        )

                        lineFragmentFrame = CGRect(
                            origin: CGPoint(
                                x: rawFrame.origin.x,
                                y: rawFrame.origin.y - contentOffset.y
                            ),
                            size: rawFrame.size
                        )
                    } else {
                        locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)

                        if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                            baselineYOffset = STGutterCalculations.calculateBaselineOffset(
                                lineHeight: textLineFragment.typographicBounds.height,
                                paragraphStyle: paragraphStyle
                            )
                        }

                        // Look up the fragment view for accurate positioning (only for normal fragments)
                        if let fragmentView = fragmentViewMap.object(forKey: layoutFragment) {
                            // Use fragment view's actual frame for positioning
                            lineFragmentFrame = CGRect(
                                origin: CGPoint(
                                    x: fragmentView.frame.origin.x + textLineFragment.typographicBounds.origin.x,
                                    y: fragmentView.frame.origin.y + textLineFragment.typographicBounds.origin.y - contentOffset.y
                                ),
                                size: CGSize(
                                    width: fragmentView.frame.width,
                                    height: fragmentView.frame.height
                                )
                            )
                        } else {
                            lineFragmentFrame = CGRect(
                                origin: CGPoint(
                                    x: layoutFragment.layoutFragmentFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                                    y: layoutFragment.layoutFragmentFrame.origin.y + textLineFragment.typographicBounds.origin.y - contentOffset.y
                                ),
                                size: CGSize(
                                    width: layoutFragment.layoutFragmentFrame.width, // extend width to he fragment layout for the convenience of gutter
                                    height: layoutFragment.layoutFragmentFrame.height
                                )
                            )
                        }
                    }

                    var effectiveLineTextAttributes = lineTextAttributes
                    if highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
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
                        numberCell.backgroundColor = gutterView.selectedLineHighlightColor
                    }

                    numberCell.frame = CGRect(
                        origin: CGPoint(
                            x: 0,
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
