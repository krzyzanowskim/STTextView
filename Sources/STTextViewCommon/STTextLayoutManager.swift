//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

import STTextKitPlus

open class STTextLayoutManager: NSTextLayoutManager {

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        /// Posted when the selected range of characters changes.
        public static let didChangeSelectionNotification = NSTextView.didChangeSelectionNotification
    #else
        /// Posted when the selected range of characters changes.
        public static let didChangeSelectionNotification = NSNotification.Name("STTextView.didChangeSelectionNotification")
    #endif

    override public var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }
}
