//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView {

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    internal var isGutterVisible: Bool {
        set {
            if gutterView == nil, newValue == true {
                let gutterView = STGutterView()
                gutterView.font = adjustGutterFont(font)
                gutterView.frame.size.width = gutterView.minimumThickness
                gutterView.selectedLineTextColor = textColor
                gutterView.highlightSelectedLine = highlightSelectedLine
                gutterView.selectedLineHighlightColor = selectedLineHighlightColor
                self.addSubview(gutterView)
                self.gutterView = gutterView
            } else if newValue == false {
                gutterView?.removeFromSuperview()
                gutterView = nil
            }
            layoutGutter()
        }
        get {
            gutterView != nil
        }
    }

    internal func layoutGutter() {
        if let gutterView {
            gutterView.frame.origin = contentOffset
            gutterView.frame.size.height = visibleSize.height
        }

        layoutGutterLineNumbers()
    }

    private func layoutGutterLineNumbers() {
        guard let gutterView, let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return
        }

        gutterView.containerView.subviews.forEach { v in
            v.removeFromSuperview()
        }

        let textElements = textContentManager.textElements(
            for: NSTextRange(
                location: textLayoutManager.documentRange.location,
                end: viewportRange.location
            )!
        )

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: gutterView.font,
            .foregroundColor: UIColor.secondaryLabel.cgColor
        ]

        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (gutterView.selectedLineTextColor ?? gutterView.textColor).cgColor
        ]

        var requiredWidthFitText = gutterView.minimumThickness
        let startLineIndex = textElements.count
        var linesCount = 0
        textLayoutManager.enumerateTextLayoutFragments(in: viewportRange) { layoutFragment in
            let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

            for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {

                func isLineSelected() -> Bool {
                    textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
                        var result = true
                        if lineFragment.isExtraLineFragment {
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

                var baselineYOffset: CGFloat = 0
                if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                    baselineYOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                }

                let lineNumber = startLineIndex + linesCount + 1
                let locationForFirstCharacter = lineFragment.locationForCharacter(at: 0)

                var lineFragmentFrame = CGRect(origin: CGPoint(x: 0, y: layoutFragment.layoutFragmentFrame.origin.y - contentOffset.y), size: layoutFragment.layoutFragmentFrame.size)

                lineFragmentFrame.origin.y += lineFragment.typographicBounds.origin.y
                if lineFragment.isExtraLineFragment {
                    lineFragmentFrame.size.height = lineFragment.typographicBounds.height
                } else if !lineFragment.isExtraLineFragment, let extraLineFragment = layoutFragment.textLineFragments.first(where: { $0.isExtraLineFragment }) {
                    lineFragmentFrame.size.height -= extraLineFragment.typographicBounds.height
                }

                var effectiveLineTextAttributes = lineTextAttributes
                if highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                    effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
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
                        x: bounds.minX,
                        y: lineFragmentFrame.origin.y
                    ),
                    size: CGSize(
                        width: max(lineFragmentFrame.intersection(gutterView.containerView.frame).width, gutterView.containerView.frame.width),
                        height: lineFragmentFrame.size.height
                    )
                )

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
