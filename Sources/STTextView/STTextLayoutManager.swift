//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class STTextLayoutManager: NSTextLayoutManager {

    override var textSelections: [NSTextSelection] {
        didSet {
            NotificationCenter.default.post(
                Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            )
        }
    }

}
