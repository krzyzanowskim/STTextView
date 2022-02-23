//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class STTextLayoutManager: NSTextLayoutManager {

    static let didChangeSelectionNotification = STTextView.didChangeSelectionNotification

    override var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: STTextLayoutManager.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }

}
