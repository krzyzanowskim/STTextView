//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus
import CoreTextSwift
import STTextViewCommon

extension STTextView {

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    var isGutterVisible: Bool {
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

    func layoutGutter() {
        guard let gutterView, textLayoutManager.textViewportLayoutController.viewportRange != nil else {
            return
        }

        // Coordinate system strategy:
        // The gutter is positioned to scroll with the content in the Y direction (same as content view)
        // but floats in the X direction (stays at contentOffset.x to remain visible during horizontal scroll).
        // This ensures line numbers always align with their corresponding text lines.
        gutterView.frame.origin.x = contentOffset.x
        gutterView.frame.origin.y = textContainerInset.top
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
                        y: selectionFrame.origin.y
                    ),
                    size: CGSize(
                        width: gutterView.containerView.frame.width,
                        height: typingLineHeight
                    )
                ).pixelAligned

                gutterView.containerView.addSubview(numberCell)
            }
        } else if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            // Get visible fragment views from the map and sort by document order
            let visibleFragmentViews = STGutterCalculations.visibleFragmentViewsInViewport(
                fragmentViewMap: fragmentViewMap,
                viewportRange: viewportRange
            )

            guard !visibleFragmentViews.isEmpty else {
                return
            }

            // Calculate how many lines exist before the viewport
            let textElementsBeforeViewport = textContentManager.textElements(
                for: NSTextRange(
                    location: textLayoutManager.documentRange.location,
                    end: viewportRange.location
                )!
            )

            var requiredWidthFitText = gutterView.minimumThickness
            let startLineIndex = textElementsBeforeViewport.count
            var linesCount = 0

            for (layoutFragment, fragmentView) in visibleFragmentViews {
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

                // Only show line numbers for the first line fragment or extra line fragments
                for textLineFragment in layoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == textLineFragment) {
                    let lineNumber = startLineIndex + linesCount + 1

                    // Determine if this line is selected
                    let isLineSelected = STGutterCalculations.isLineSelected(
                        textLineFragment: textLineFragment,
                        layoutFragment: layoutFragment,
                        contentRangeInElement: contentRangeInElement,
                        textLayoutManager: textLayoutManager
                    )

                    // Calculate positioning metrics
                    // Get the actual fragment view frame for pixel-perfect alignment
                    // Pass .zero for contentOffset since gutter now scrolls with content (no compensation needed)
                    let (baselineYOffset, locationForFirstCharacter, lineFragmentFrame) = STGutterCalculations.calculateLineNumberMetrics(
                        for: textLineFragment,
                        in: layoutFragment,
                        fragmentViewFrame: fragmentView.frame,
                        contentOffset: .zero
                    )

                    // Prepare text attributes
                    var effectiveLineTextAttributes = lineTextAttributes
                    if highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                        effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                    }
                    if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                        effectiveLineTextAttributes[.paragraphStyle] = paragraphStyle
                    }

                    // Create and configure line number cell
                    let numberCell = STGutterLineNumberCell(
                        firstBaseline: locationForFirstCharacter.y + baselineYOffset,
                        attributes: effectiveLineTextAttributes,
                        number: lineNumber
                    )
                    numberCell.insets = gutterView.insets

                    // Apply selection highlight if needed
                    if gutterView.highlightSelectedLine, isLineSelected,
                       textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty,
                       !textLayoutManager.insertionPointSelections.isEmpty {
                        numberCell.backgroundColor = gutterView.selectedLineHighlightColor
                    }

                    // Position the cell
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
            }

            // adjust ruleThickness to fit the text based on last numberView
            if textLayoutManager.textViewportLayoutController.viewportRange != nil {
                let newGutterWidth = max(requiredWidthFitText, gutterView.minimumThickness)
                if !newGutterWidth.isAlmostEqual(to: gutterView.frame.size.width, tolerance: .ulpOfOne), newGutterWidth > gutterView.frame.size.width {
                    gutterView.frame.size.width = newGutterWidth
                }
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
