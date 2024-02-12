//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class STTextLayoutManager: NSTextLayoutManager {

    private static let needsBoundsWorkaround = testIfNeedsBoundsWorkaround()

    override var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }

    override var usageBoundsForTextContainer: CGRect {
        var rect = super.usageBoundsForTextContainer
        if Self.needsBoundsWorkaround {
            // FB13290979: NSTextContainer.lineFragmentPadding does not affect end of the fragment usageBoundsForTextContainer rectangle
            // https://gist.github.com/krzyzanowskim/7adc5ee66be68df2f76b9752476aadfb
            rect.size.width += textContainer?.lineFragmentPadding ?? 0
        }
        return rect
    }

}


// FB13290979: NSTextContainer.lineFragmentPadding does not affect end of the fragment usageBoundsForTextContainer rectangle
private func testIfNeedsBoundsWorkaround() -> Bool {
    let textContentManager = NSTextContentStorage()
    let textLayoutManager = NSTextLayoutManager()
    textContentManager.addTextLayoutManager(textLayoutManager)
    textContentManager.primaryTextLayoutManager = textLayoutManager

    let textContainer = NSTextContainer()
    textLayoutManager.textContainer = textContainer

    textContentManager.attributedString = NSAttributedString(string: "01234567890123456789")

    textContainer.lineFragmentPadding = 5
    textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
    let bounds1 = textLayoutManager.usageBoundsForTextContainer

    textContainer.lineFragmentPadding = 0
    textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
    let bounds2 = textLayoutManager.usageBoundsForTextContainer

    if bounds1.width == bounds2.width {
        return true
    }

    return false
}
