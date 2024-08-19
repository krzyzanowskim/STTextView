//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import UIKit
import STTextViewCommon

/// A gutter to the side of a scroll view’s document view.
public final class STGutterView: UIView {
    internal let containerView: UIView

    /// The font used to draw line numbers.
    ///
    /// Initialized with a textView font value and does not update automatically when
    /// text view font changes.
    @Invalidating(.display)
    public var font: UIFont = adjustGutterFont(UIFont(descriptor: UIFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.traitCondensed)!, size: 0))

    /// The insets of the ruler view.
    @Invalidating(.display)
    public var insets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)

    /// Minimum thickness.
    @Invalidating(.layout)
    public var minimumThickness: CGFloat = 40

    /// The text color of the line numbers.
    @Invalidating(.display)
    public var textColor = UIColor.secondaryLabel

    /// A Boolean indicating whether to draw a separator or not. Default true.
    @Invalidating(.display)
    public var drawSeparator: Bool = true

    /// A Boolean that controls whether the text view highlights the currently selected line. Default false.
    @Invalidating(.display)
    public var highlightSelectedLine: Bool = false

    /// A Boolean value that indicates whether the receiver draws its background. Default true.
    @Invalidating(.display)
    public var drawsBackground: Bool = true

    /// The background color of the highlighted line.
    @Invalidating(.display)
    public var selectedLineHighlightColor: UIColor = .tintColor.withAlphaComponent(0.15)

    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    public var selectedLineTextColor: UIColor? = nil

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    @Invalidating(.display)
    public var separatorColor = UIColor.separator.withAlphaComponent(0.1)

    override init(frame: CGRect) {
        containerView = UIView(frame: frame)
        containerView.clipsToBounds = true
        containerView.isOpaque = true
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false

        addSubview(containerView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if drawsBackground {
            backgroundColor = UIColor.systemBackground.resolvedColor(with: traitCollection)
        }
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        if drawSeparator {
            context.setLineWidth(1)
            context.setStrokeColor(separatorColor.cgColor)
            context.addLines(between: [CGPoint(x: frame.width - 0.5, y: 0), CGPoint(x: frame.width - 0.5, y: bounds.maxY) ])
            context.strokePath()
        }
    }
}

func adjustGutterFont(_ font: UIFont) -> UIFont {
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

    let adjustedFont = UIFont(descriptor: font.fontDescriptor.addingAttributes([.featureSettings: features]), size: max(font.pointSize * 0.9, UIFont.smallSystemFontSize))
    return adjustedFont
}
