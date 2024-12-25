//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//  STGutterView
//      |- STGutterContainerView
//           |-STGutterLineNumberCell
//

import AppKit
import STTextViewCommon

/// A gutter to the side of a scroll view’s document view.
open class STGutterView: NSView {
    internal let containerView: STGutterContainerView

    /// The font used to draw line numbers.
    ///
    /// Initialized with a textView font value and does not update automatically when
    /// text view font changes.
    @Invalidating(.display)
    open var font = adjustGutterFont(NSFont(descriptor: NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.condensed), size: 0)!)

    /// The insets of the ruler view.
    @Invalidating(.display)
    open var insets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)

    /// Minimum thickness.
    @Invalidating(.layout)
    open var minimumThickness: CGFloat = 40

    /// The text color of the line numbers.
    @Invalidating(.display)
    open var textColor = NSColor.secondaryLabelColor

    /// A Boolean indicating whether to draw a separator or not. Default true.
    @Invalidating(.display)
    open var drawSeparator: Bool = true

    /// A Boolean that controls whether the text view highlights the currently selected line. Default false.
    @Invalidating(.display)
    open var highlightSelectedLine: Bool = false

    /// A Boolean value that indicates whether the receiver draws its background. Default true.
    @Invalidating(.display)
    open var drawsBackground: Bool = true {
        didSet {
            updateBackgrundColor()
        }
    }

    @Invalidating(.display)
    internal var backgroundColor: NSColor = NSColor.controlBackgroundColor

    /// The background color of the highlighted line.
    @Invalidating(.display)
    open var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)

    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    open var selectedLineTextColor: NSColor? = nil

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    @Invalidating(.display)
    open var separatorColor = NSColor.separatorColor.withAlphaComponent(0.1)

    public override var isOpaque: Bool {
        false
    }

    override init(frame: CGRect) {
        containerView = STGutterContainerView(frame: frame)
        containerView.autoresizingMask = [.width, .height]

        super.init(frame: frame)
        wantsLayer = true
        clipsToBounds = true
        addSubview(containerView)

        updateBackgrundColor()
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            updateBackgrundColor()
        }
    }

    private func updateBackgrundColor() {
        if drawsBackground {
            layer?.backgroundColor = backgroundColor.cgColor
        } else {
            layer?.backgroundColor = nil
        }
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = NSGraphicsContext.current?.cgContext else {
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

private func adjustGutterFont(_ font: NSFont) -> NSFont {
    // https://useyourloaf.com/blog/ios-9-proportional-numbers/
    // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM09/AppendixF.html
    let features: [[NSFontDescriptor.FeatureKey: Int]] = [
        [
            .typeIdentifier: kTextSpacingType,
            .selectorIdentifier: kMonospacedTextSelector
        ],
        [
            .typeIdentifier: kNumberSpacingType,
            .selectorIdentifier: kMonospacedNumbersSelector
        ],
        [
            .typeIdentifier: kNumberCaseType,
            .selectorIdentifier: kUpperCaseNumbersSelector
        ],
        [
            .typeIdentifier: kStylisticAlternativesType,
            .selectorIdentifier: kStylisticAltOneOnSelector
        ],
        [
            .typeIdentifier: kStylisticAlternativesType,
            .selectorIdentifier: kStylisticAltTwoOnSelector
        ],
        [
            .typeIdentifier: kTypographicExtrasType,
            .selectorIdentifier: kSlashedZeroOnSelector
        ]
    ]

    return NSFont(descriptor: font.fontDescriptor.addingAttributes([.featureSettings: features]), size: 0) ?? font
}
