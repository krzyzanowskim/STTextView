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
