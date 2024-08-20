//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    @objc public func toggleRuler(_ sender: Any?) {
        isGutterVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    public var isGutterVisible: Bool {
        set {
            if gutterView == nil, newValue == true {
                let gutterView = STGutterView()
                if let font {
                    gutterView.font = adjustGutterFont(font)
                }
                gutterView.frame.size.width = gutterView.minimumThickness
                if let textColor {
                    gutterView.selectedLineTextColor = textColor
                }
                gutterView.highlightSelectedLine = highlightSelectedLine
                gutterView.selectedLineHighlightColor = selectedLineHighlightColor
                if let scrollView = enclosingScrollView {
                    scrollView.addSubview(gutterView)
                    needsLayout = true
                }
                self.gutterView = gutterView
            } else if newValue == false {
                if let gutterView {
                    gutterView.removeFromSuperview()
                    needsLayout = true
                }
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
            gutterView.frame.origin = frame.origin
            gutterView.frame.size.height = scrollView?.bounds.height ?? frame.height
        }

        layoutGutterLineNumbers()
    }

    private func layoutGutterLineNumbers() {
        guard let gutterView, let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return
        }

        gutterView.containerView.subviews.forEach { v in
            v.removeFromSuperviewWithoutNeedingDisplay()
        }

        let textElements = textContentManager.textElements(
            for: NSTextRange(
                location: textLayoutManager.documentRange.location,
                end: viewportRange.location
            )!
        )

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: gutterView.font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        var requiredWidthFitText = gutterView.minimumThickness
        let startLineIndex = textElements.count
        var linesCount = 0
        textLayoutManager.enumerateTextLayoutFragments(in: viewportRange) { layoutFragment in
            for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {
                var baselineYOffset: CGFloat = 0
                if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                    baselineYOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                }

                let lineNumber = startLineIndex + linesCount + 1
                let locationForFirstCharacter = lineFragment.locationForCharacter(at: 0)

                var lineFragmentFrame = CGRect(origin: CGPoint(x: 0, y: layoutFragment.layoutFragmentFrame.origin.y - scrollView!.contentView.bounds.minY/*contentOffset.y*/), size: layoutFragment.layoutFragmentFrame.size)

                lineFragmentFrame.origin.y += lineFragment.typographicBounds.origin.y
                if lineFragment.isExtraLineFragment {
                    lineFragmentFrame.size.height = lineFragment.typographicBounds.height
                } else if !lineFragment.isExtraLineFragment, let extraLineFragment = layoutFragment.textLineFragments.first(where: { $0.isExtraLineFragment }) {
                    lineFragmentFrame.size.height -= extraLineFragment.typographicBounds.height
                }

                let effectiveLineTextAttributes = lineTextAttributes
                let numberCell = STGutterLineNumberCell(
                    firstBaseline: locationForFirstCharacter.y + baselineYOffset,
                    attributes: effectiveLineTextAttributes,
                    number: lineNumber
                )

                numberCell.insets = gutterView.insets

                numberCell.frame = CGRect(
                    origin: lineFragmentFrame.origin,
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
