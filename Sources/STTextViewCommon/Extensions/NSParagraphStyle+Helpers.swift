//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

package extension NSParagraphStyle {

    /// Normalized value for default paragraph style
    /// NSParagraphStyle.lineHeightMultiple means "default" multiple, that is 1.0
    var stLineHeightMultiple: CGFloat {
        if lineHeightMultiple.isAlmostZero() {
            return 1.0
        } else {
            return lineHeightMultiple
        }
    }
}
