//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class STTextLayoutManager: NSTextLayoutManager {

    override var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }

    override var usageBoundsForTextContainer: CGRect {
        var rect = super.usageBoundsForTextContainer
        // FB13290979: NSTextContainer.lineFragmentPadding does not affect end of the fragment usageBoundsForTextContainer rectangle
        // https://gist.github.com/krzyzanowskim/7adc5ee66be68df2f76b9752476aadfb
        rect.size.width += textContainer?.lineFragmentPadding ?? 0
        return rect
    }

}
