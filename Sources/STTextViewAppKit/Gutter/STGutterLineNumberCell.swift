//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextViewCommon

final class STGutterLineNumberCell: NSView {
    /// Line number
    let lineNumber: Int
    let firstBaseline: CGFloat
    /// Y position from cell top to the visual center of the line number text
    let textVisualCenter: CGFloat
    private let ctLine: CTLine
    let textSize: CGSize
    var insets = STRulerInsets()

    override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        nil
    }

    override var debugDescription: String {
        "\(super.debugDescription) (number: \(lineNumber))"
    }

    override var firstBaselineOffsetFromTop: CGFloat {
        firstBaseline
    }

    init(firstBaseline: CGFloat, attributes: [NSAttributedString.Key: Any], number: Int) {
        self.lineNumber = number
        self.firstBaseline = firstBaseline

        let attributedString = NSAttributedString(string: "\(number)", attributes: attributes)
        self.ctLine = CTLineCreateWithAttributedString(attributedString)

        // Get actual typographic metrics to calculate visual center
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let typographicsBoundsWidth = CTLineGetTypographicBounds(ctLine, &ascent, &descent, nil)

        // Calculate visual center: baseline + (descent - ascent) / 2
        // This gives us the Y position from cell top to the visual middle of the text
        self.textVisualCenter = firstBaseline + (descent - ascent) / 2

        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            let lineHeight = floor(ctLine.height() * paragraphStyle.stLineHeightMultiple)
            self.textSize = CGSize(width: ceil(typographicsBoundsWidth), height: lineHeight)
        } else {
            self.textSize = CGSize(width: ceil(typographicsBoundsWidth), height: ctLine.height())
        }

        super.init(frame: CGRect(origin: .zero, size: textSize))
        wantsLayer = true
        clipsToBounds = true

        if ProcessInfo().environment["ST_LAYOUT_DEBUG"] == "YES" {
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.05).cgColor
            layer?.borderColor = NSColor.systemOrange.cgColor
            layer?.borderWidth = 0.5
        }
    }

    override var isFlipped: Bool {
        true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: textSize.width + insets.horizontal, height: textSize.height)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            return
        }

        ctx.saveGState()
        ctx.textMatrix = CGAffineTransform(scaleX: 1, y: isFlipped ? -1 : 1)

        // align to right
        ctx.textPosition = CGPoint(x: frame.width - (textSize.width + insets.trailing), y: firstBaseline)
        CTLineDraw(ctLine, ctx)
        ctx.restoreGState()
    }
}
