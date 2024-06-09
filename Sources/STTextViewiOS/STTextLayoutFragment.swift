//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STObjCLandShim

final class STTextLayoutFragment: NSTextLayoutFragment {
    private let paragraphStyle: NSParagraphStyle

    init(textElement: NSTextElement, range rangeInElement: NSTextRange?, paragraphStyle: NSParagraphStyle) {
        self.paragraphStyle = paragraphStyle
        super.init(textElement: textElement, range: rangeInElement)
    }

    required init?(coder: NSCoder) {
        self.paragraphStyle = NSParagraphStyle.default
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
        context.restoreGState()
    }
}
