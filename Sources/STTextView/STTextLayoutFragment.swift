//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class STTextLayoutFragment: NSTextLayoutFragment {
    private let paragraphStyle: NSParagraphStyle
    var showsInvisibleCharacters: Bool = false

    init(textElement: NSTextElement, range rangeInElement: NSTextRange?, paragraphStyle: NSParagraphStyle) {
        self.paragraphStyle = paragraphStyle
        super.init(textElement: textElement, range: rangeInElement)
    }

    required init?(coder: NSCoder) {
        self.paragraphStyle = NSParagraphStyle.default
        self.showsInvisibleCharacters = false
        super.init(coder: coder)
    }

    // Provide default line height based on the typingattributed. By default return (0, 0, 10, 14)
    //
    // override var layoutFragmentFrame: CGRect {
    //    super.layoutFragmentFrame
    // }

    override func draw(at point: CGPoint, in context: CGContext) {
        // Layout fragment draw text at the bottom (after apply baselineOffset) but ignore the paragraph line height
        // This is a workaround/patch to position text nicely in the line
        //
        // Center vertically after applying lineHeightMultiple value
        // super.draw(at: point.moved(dx: 0, dy: offset), in: context)
        for lineFragment in textLineFragments {

            // Determine paragraph style. Either from the fragment string or default for the text view
            // the ExtraLineFragment doesn't have information about typing attributes hence layout manager uses a default values - not from text view
            let paragraphStyle: NSParagraphStyle
            if !lineFragment.isExtraLineFragment,
               let lineParagraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            {
                paragraphStyle = lineParagraphStyle
            } else {
                paragraphStyle = self.paragraphStyle
            }

            if !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                let offset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                lineFragment.draw(at: point.moved(dx: lineFragment.typographicBounds.origin.x, dy: lineFragment.typographicBounds.origin.y + offset), in: context)
            } else {
                lineFragment.draw(at: lineFragment.typographicBounds.origin, in: context)
            }
        }

        if showsInvisibleCharacters {
            drawInvisibles(in: context)
        }
    }

    private func drawInvisibles(in context: CGContext) {
        guard let textLayoutManager = textLayoutManager else {
            return
        }

        context.saveGState()

        for lineFragment in textLineFragments where !lineFragment.isExtraLineFragment {
            let string = lineFragment.attributedString.string
            if let textLineTextRange = lineFragment.textRange(in: self) {
                for (offset, character) in string.utf16.enumerated() where Unicode.Scalar(character)?.properties.isWhitespace == true {
                    // FIXME: if fail to draw for right-to-left writing direction
                    let writingDirection = textLayoutManager.baseWritingDirection(at: textLineTextRange.location)
                    guard let segmentLocation = textLayoutManager.location(textLineTextRange.location, offsetBy: offset),
                          let segmentEndLocation = textLayoutManager.location(textLineTextRange.location, offsetBy: offset + (writingDirection == .leftToRight ? 1 : 0)),
                          let segmentRange = NSTextRange(location: segmentLocation, end: segmentEndLocation),
                          let segmentFrame = textLayoutManager.textSegmentFrame(in: segmentRange, type: .standard)
                    else {
                        assertionFailure()
                        continue
                    }

                    let frameRect = CGRect(origin: CGPoint(x: segmentFrame.origin.x, y: segmentFrame.origin.y - layoutFragmentFrame.origin.y), size: CGSize(width: segmentFrame.size.width, height: segmentFrame.size.height))
                    context.setFillColor(NSColor.placeholderTextColor.cgColor)
                    let rect = CGRect(x: frameRect.midX - (frameRect.width / 8), y: frameRect.minY + (frameRect.height * 0.5), width: frameRect.width / 4, height: frameRect.width / 4)
                    context.addEllipse(in: rect)
                    context.drawPath(using: .fill)
                }
            }
        }

        context.restoreGState()
    }
}
