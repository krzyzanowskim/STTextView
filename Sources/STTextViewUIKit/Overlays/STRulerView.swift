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

    /// A Boolean indicating whether to draw a separator or not.
    @Invalidating(.display)
    public var drawSeparator: Bool = true

    /// The insets of the ruler view.
    @Invalidating(.display)
    public var rulerInsets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)

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
        backgroundColor = UIColor.systemBackground.resolvedColor(with: traitCollection)
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }

        if drawSeparator {
            ctx.setLineWidth(1)
            ctx.setStrokeColor(UIColor.separator.cgColor)
            ctx.addLines(between: [CGPoint(x: frame.width - 0.5, y: 0), CGPoint(x: frame.width - 0.5, y: bounds.maxY) ])
            ctx.strokePath()
        }
    }
}
