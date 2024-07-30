//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextViewCommon

public final class STRulerView: UIView {
    internal let lineNumberViewContainer: STLineNumberViewContainer

    /// The font used to draw line numbers.
    ///
    /// Initialized with a textView font value and does not update automatically when
    /// text view font changes.
    @Invalidating(.display)
    public var font: UIFont = adjustFont(UIFont(descriptor: UIFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.traitCondensed)!, size: 0))

    /// The insets of the ruler view.
    @Invalidating(.display)
    public var rulerInsets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)

    /// The text color of the line numbers.
    @Invalidating(.display)
    public var textColor: UIColor = .secondaryLabel

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
    public var selectedLineHighlightColor: UIColor = UIColor.tintColor.withAlphaComponent(0.15)

    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    public var selectedLineTextColor: UIColor? = nil

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    @Invalidating(.display)
    public var separatorColor: UIColor = UIColor.separator

    override init(frame: CGRect) {
        lineNumberViewContainer = STLineNumberViewContainer(frame: frame)
        lineNumberViewContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false

        addSubview(lineNumberViewContainer)
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
