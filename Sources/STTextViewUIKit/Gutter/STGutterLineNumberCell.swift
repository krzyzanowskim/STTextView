//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextViewCommon

final class STGutterLineNumberCell: UIView {
    private let number: Int
    private let firstBaseline: CGFloat
    private let ctLine: CTLine
    private let textWidth: CGFloat
    var insets: STRulerInsets = STRulerInsets()

    init(firstBaseline: CGFloat, attributes: [NSAttributedString.Key: Any], number: Int) {
        self.number = number
        self.firstBaseline = firstBaseline

        let attributedString = NSAttributedString(string: "\(number)", attributes: attributes)
        self.ctLine = CTLineCreateWithAttributedString(attributedString)
        self.textWidth = ceil(CTLineGetTypographicBounds(ctLine, nil, nil, nil))

        super.init(frame: .zero)
        clipsToBounds = true
        isOpaque = false
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: textWidth + insets.trailing + insets.leading, height: 14)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }

        ctx.saveGState()
        ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)

        // align to right
        ctx.textPosition = CGPoint(x: frame.width - (textWidth + insets.trailing), y: firstBaseline)
        CTLineDraw(ctLine, ctx)
        ctx.restoreGState()
    }
}
