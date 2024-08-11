//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STObjCLandShim

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

        context.saveGState()

#if USE_FONT_SMOOTHING_STYLE
        // This seems to be available at least on 10.8 and later. The only reference to it is in
        // WebKit. This causes text to render just a little lighter, which looks nicer.
        let useThinStrokes = true // shouldSmooth
        var savedFontSmoothingStyle: Int32 = 0

        if useThinStrokes {
            context.setShouldSmoothFonts(true)
            savedFontSmoothingStyle = STContextGetFontSmoothingStyle(context)
            STContextSetFontSmoothingStyle(context, 16)
        }
#endif

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

#if USE_FONT_SMOOTHING_STYLE
        if (useThinStrokes) {
            STContextSetFontSmoothingStyle(context, savedFontSmoothingStyle);
        }
#endif

        if showsInvisibleCharacters {
            drawInvisibles(at: point, in: context)
        }
        
        context.restoreGState()
    }
  
    private func drawInvisibles(at point: CGPoint, in context: CGContext) {
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
                        // assertionFailure()
                        continue
                    }
                    
                    if character.isLineBreak == true {
                        drawNewLinePlaceholder(at: offset, segmentFrame: segmentFrame, context: context)
                    } else  {
                        drawPlaceholder(at: offset, segmentFrame: segmentFrame, context: context)
                    }
                }
            }
        }

        context.restoreGState()
    }

    private func drawPlaceholder(at offset: Int, segmentFrame: CGRect, context: CGContext) {
        let frameRect = CGRect(origin: CGPoint(x: segmentFrame.origin.x - layoutFragmentFrame.origin.x, y: segmentFrame.origin.y - layoutFragmentFrame.origin.y), size: CGSize(width: segmentFrame.size.width, height: segmentFrame.size.height))
        context.setFillColor(NSColor.placeholderTextColor.cgColor)
        let rect = CGRect(x: frameRect.midX, y: frameRect.midY, width: frameRect.width / 4, height: frameRect.width / 4)
        context.addEllipse(in: rect)
        context.drawPath(using: .fill)
    }

    private func drawNewLinePlaceholder(at offset: Int, segmentFrame: CGRect, context: CGContext) {
        let frameRect = CGRect(origin: CGPoint(x: segmentFrame.origin.x - layoutFragmentFrame.origin.x, y: segmentFrame.origin.y - layoutFragmentFrame.origin.y), size: CGSize(width: 20, height: segmentFrame.size.height))
        context.setStrokeColor(NSColor.placeholderTextColor.cgColor)
        let path = createNewLinePath(in: frameRect)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }

    /// Create the path for the `¬` shape.
    private func createNewLinePath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()

        let lineWidth: CGFloat = rect.width / 2
        let lineHeight: CGFloat = rect.width / 4

        // Horizontal line
        path.move(to: CGPoint(x: rect.midX - lineWidth / 2, y: rect.midY - lineHeight/2))
        path.addLine(to: CGPoint(x: rect.midX + lineWidth / 2, y: rect.midY - lineHeight/2))
        
        // Vertical line
        path.move(to: CGPoint(x: rect.midX + lineWidth / 2, y: rect.midY - lineHeight/2))
        path.addLine(to: CGPoint(x: rect.midX + lineWidth / 2, y: rect.midY + lineHeight/2))

        return path
    }


}

extension String.UTF16View.Element {
    var isLineBreak: Bool {
        return self == 0x000A || // Line Feed (LF, \n)
               self == 0x000D || // Carriage Return (CR, \r)
               self == 0x2028 || // Line Separator
               self == 0x2029    // Paragraph Separator
    }
}
