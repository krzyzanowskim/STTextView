//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import CoreTextSwift
import STTextViewCommon

final class STGutterLineNumberCell: UIView {
    /// Line number
    let lineNumber: Int
    /// Y position from cell top to the visual center of the line number text
    var textVisualCenter: CGFloat { bounds.height / 2 }
    private let ctLine: CTLine
    private let ascent: CGFloat
    private let descent: CGFloat
    let textSize: CGSize
    var insets = STRulerInsets()

    private var firstBaselineOffsetFromTop: CGFloat {
        textVisualCenter + ((ascent - descent) / 2)
    }

    override var debugDescription: String {
        "\(super.debugDescription) (number: \(lineNumber))"
    }

    init(attributes: [NSAttributedString.Key: Any], number: Int) {
        self.lineNumber = number

        let attributedString = NSAttributedString(string: "\(number)", attributes: attributes)
        self.ctLine = CTLineCreateWithAttributedString(attributedString)

        // Get actual typographic metrics to calculate visual center
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let typographicsBoundsWidth = CTLineGetTypographicBounds(ctLine, &ascent, &descent, nil)
        self.ascent = ascent
        self.descent = descent

        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            let lineHeight = floor(ctLine.height() * paragraphStyle.stLineHeightMultiple)
            self.textSize = CGSize(width: ceil(typographicsBoundsWidth), height: lineHeight)
        } else {
            self.textSize = CGSize(width: ceil(typographicsBoundsWidth), height: ctLine.height())
        }

        super.init(frame: CGRect(origin: .zero, size: textSize))
        clipsToBounds = true
        isOpaque = false
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: textSize.width + insets.horizontal, height: textSize.height)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }

        ctx.saveGState()
        ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)

        ctx.textPosition = CGPoint(
            x: bounds.width - (textSize.width + insets.trailing),
            y: bounds.minY + firstBaselineOffsetFromTop
        )
        CTLineDraw(ctLine, ctx)
        ctx.restoreGState()
    }
}
