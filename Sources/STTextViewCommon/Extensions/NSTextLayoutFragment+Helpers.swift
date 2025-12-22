//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

import STTextKitPlus

public extension NSTextLayoutFragment {

    /// FB15131180 workaround: Extra line fragment's layoutFragmentFrame is miscalculated.
    var stTypographicBounds: CGRect {
        guard isExtraLineFragment else {
            return layoutFragmentFrame
        }

        let fallbackLineHeight: CGFloat
        if let textParagraph = textElement as? NSTextParagraph,
           textParagraph.attributedString.length > 0 {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                if let font = textParagraph.attributedString.attribute(.font, at: 0, effectiveRange: nil) as? NSFont {
                    fallbackLineHeight = ceil(font.ascender - font.descender + font.leading)
                } else {
                    fallbackLineHeight = 14
                }
            #elseif canImport(UIKit)
                if let font = textParagraph.attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
                    fallbackLineHeight = ceil(font.ascender - font.descender + font.leading)
                } else {
                    fallbackLineHeight = 14
                }
            #endif
        } else {
            fallbackLineHeight = 14
        }

        return stTypographicBounds(fallbackLineHeight: fallbackLineHeight)
    }

    /// FB15131180 workaround: Extra line fragment's layoutFragmentFrame is miscalculated.
    func stTypographicBounds(fallbackLineHeight: CGFloat) -> CGRect {
        guard isExtraLineFragment else {
            return layoutFragmentFrame
        }

        let height = textLineFragments.reduce(0) { sum, lineFragment in
            if lineFragment.isExtraLineFragment {
                if textLineFragments.count >= 2 {
                    let prevLineFragment = textLineFragments[textLineFragments.count - 2]
                    return sum + prevLineFragment.typographicBounds.height
                } else {
                    return sum + fallbackLineHeight
                }
            } else {
                return sum + lineFragment.typographicBounds.height
            }
        }

        return CGRect(
            origin: layoutFragmentFrame.origin,
            size: CGSize(width: layoutFragmentFrame.width, height: height)
        )
    }
}
