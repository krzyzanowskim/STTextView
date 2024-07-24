//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

private let lineTextAttributes: [NSAttributedString.Key: Any] = [
    .font: adjustFont(UIFont(descriptor: UIFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.traitCondensed)!, size: 0)),
    .foregroundColor: UIColor.secondaryLabel.cgColor
]

final class STLineNumberView: UIView {

    final class NumberView: UIView {
        let number: Int
        let firstBaseline: CGFloat
        let ctLine: CTLine

        init(firstBaseline: CGFloat, number: Int) {
            self.number = number
            self.firstBaseline = firstBaseline

            let attributedString = NSAttributedString(string: "\(number)", attributes: lineTextAttributes)
            self.ctLine = CTLineCreateWithAttributedString(attributedString)

            super.init(frame: .zero)
            isOpaque = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)

            guard let ctx = UIGraphicsGetCurrentContext() else {
                return
            }

            ctx.saveGState()
            ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            ctx.textPosition = CGPoint(x: 5, y: firstBaseline)
            CTLineDraw(ctLine, ctx)
            ctx.restoreGState()

        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func adjustFont(_ font: UIFont) -> UIFont {
    // https://useyourloaf.com/blog/ios-9-proportional-numbers/
    // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM09/AppendixF.html
    let features: [[UIFontDescriptor.FeatureKey: Int]] = [
        [
            .type: kTextSpacingType,
            .selector: kMonospacedTextSelector
        ],
        [
            .type: kNumberSpacingType,
            .selector: kMonospacedNumbersSelector
        ],
        [
            .type: kNumberCaseType,
            .selector: kUpperCaseNumbersSelector
        ],
        [
            .type: kStylisticAlternativesType,
            .selector: kStylisticAltOneOnSelector
        ],
        [
            .type: kStylisticAlternativesType,
            .selector: kStylisticAltTwoOnSelector
        ],
        [
            .type: kTypographicExtrasType,
            .selector: kSlashedZeroOnSelector
        ]
    ]

    let adjustedFont = UIFont(descriptor: font.fontDescriptor.addingAttributes([.featureSettings: features]), size: font.pointSize)
    return adjustedFont
}
