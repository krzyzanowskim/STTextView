//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

import STTextKitPlus

package final class STTextLayoutManager: NSTextLayoutManager {

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Posted when the selected range of characters changes.
    package static let didChangeSelectionNotification = NSTextView.didChangeSelectionNotification
#else
    /// Posted when the selected range of characters changes.
    package static let didChangeSelectionNotification = NSNotification.Name("STTextView.didChangeSelectionNotification")
#endif

    private static let needsBoundsWorkaround = testIfNeedsBoundsWorkaround()

    package override var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }

    @objc package dynamic override var usageBoundsForTextContainer: CGRect {
        var rect = super.usageBoundsForTextContainer
        if Self.needsBoundsWorkaround {
            // FB13290979: NSTextContainer.lineFragmentPadding does not affect end of the fragment usageBoundsForTextContainer rectangle
            // https://gist.github.com/krzyzanowskim/7adc5ee66be68df2f76b9752476aadfb
            // Changed in macOS 14 https://developer.apple.com/documentation/macos-release-notes/appkit-release-notes-for-macos-14#TextKit-API-Coordinate-System-Changes
            //   NSTextLineFragment.typographicBounds.size.width doesn’t contain NSTextContainer.lineFragmentPadding
            rect.size.width += textContainer?.lineFragmentPadding ?? 0
        }
        return rect
    }

}


// Changed in macOS 14 https://developer.apple.com/documentation/macos-release-notes/appkit-release-notes-for-macos-14#TextKit-API-Coordinate-System-Changes
private func testIfNeedsBoundsWorkaround() -> Bool {
    if #available(macOS 14, iOS 17, *) {
        return true
    }

    return false
}
