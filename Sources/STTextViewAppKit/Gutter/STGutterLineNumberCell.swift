//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextViewCommon

final class STGutterLineNumberCell: NSView {
    private let number: Int
    private let firstBaseline: CGFloat
    private let ctLine: CTLine
    private let textWidth: CGFloat
    var insets: STRulerInsets = STRulerInsets()

    override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        nil
    }

    init(firstBaseline: CGFloat, attributes: [NSAttributedString.Key: Any], number: Int) {
        self.number = number
        self.firstBaseline = firstBaseline

        let attributedString = NSAttributedString(string: "\(number)", attributes: attributes)
        self.ctLine = CTLineCreateWithAttributedString(attributedString)
        self.textWidth = ceil(CTLineGetTypographicBounds(ctLine, nil, nil, nil))

        super.init(frame: .zero)
        wantsLayer = true
        clipsToBounds = true
    }

    override var isFlipped: Bool {
        true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: textWidth + insets.trailing + insets.leading, height: 14)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            return
        }

        ctx.saveGState()
        ctx.textMatrix = CGAffineTransform(scaleX: 1, y: isFlipped ? -1 : 1)

        // align to right
        ctx.textPosition = CGPoint(x: frame.width - (textWidth + insets.trailing), y: firstBaseline)
        CTLineDraw(ctLine, ctx)
        ctx.restoreGState()
    }
}
