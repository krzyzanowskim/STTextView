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

    func layoutGutter() {
        guard let gutterView, textLayoutManager.textViewportLayoutController.viewportRange != nil else {
            return
        }

        gutterView.frame.size.height = contentView.bounds.height

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
                if gutterView.highlightSelectedLine /* , isLineSelected */, !selectedLineTextAttributes.isEmpty {
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

                // For empty documents, ignore bounce scrolling by treating scroll offset as 0
                // Empty document fits in viewport, so any scroll is just bounce effect
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
                    let (baselineYOffset, locationForFirstCharacter, cellFrame) = STGutterCalculations.calculateLineNumberMetrics(
                        for: textLineFragment,
                        in: layoutFragment,
                        fragmentViewFrame: fragmentView.frame
                    )

                    // Prepare text attributes
                    var effectiveLineTextAttributes = lineTextAttributes
                    if gutterView.highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
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
                        numberCell.layer?.backgroundColor = gutterView.selectedLineHighlightColor.cgColor
                    }

                    // Position the cell
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
