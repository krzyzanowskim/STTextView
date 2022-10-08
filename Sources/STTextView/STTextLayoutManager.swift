//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

public final class STTextLayoutManager: NSTextLayoutManager {

    public override init() {
        super.init()
        delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    public override var textSelections: [NSTextSelection] {
        didSet {
            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }

}

extension STTextLayoutManager: NSTextLayoutManagerDelegate {
    public func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
        STTextLayoutFragment(
            textElement: textElement,
            range: textElement.elementRange
        )
    }
}

private final class STTextLayoutFragment: NSTextLayoutFragment {
     // override func draw(at point: CGPoint, in context: CGContext) {
     //     super.draw(at: point.moved(dx: 0, dy: -(layoutFragmentFrame.height * 0.2) / 2), in: context)
     // }

    override init(textElement: NSTextElement, range rangeInElement: NSTextRange?) {
        super.init(textElement: textElement, range: rangeInElement)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
