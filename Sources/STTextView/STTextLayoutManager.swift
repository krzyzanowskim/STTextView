//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class STTextLayoutManager: NSTextLayoutManager {

    var showsInvisibleCharacters: Bool = false

    override var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }

}
