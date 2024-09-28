//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

extension NSTextLayoutFragment {
    package var isExtraLineFragment: Bool {
        textLineFragments.contains(where: \.isExtraLineFragment)
    }
}
