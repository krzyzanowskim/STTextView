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

    // lineFragmentRange return invalid ranges FB11898356 that result in broken selection
    //override func lineFragmentRange(for point: CGPoint, inContainerAt location: NSTextLocation) -> NSTextRange? {
    //    let textRange = super.lineFragmentRange(for: point, inContainerAt: location)
    //    return textRange
    //}
}
