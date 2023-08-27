//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import AppKit

extension STTextView {

    open override func centerSelectionInVisibleArea(_ sender: Any?) {
        guard let textRange = textLayoutManager.textSelections.last?.textRanges.last else {
            return
        }

        scrollToVisible(textRange, type: .standard)
        needsDisplay = true
    }

    open override func pageUp(_ sender: Any?) {
        scrollPageUp(sender)
    }

    open override func pageUpAndModifySelection(_ sender: Any?) {
        pageUp(sender)
    }

    open override func pageDown(_ sender: Any?) {
        scrollPageDown(sender)
    }

    open override func pageDownAndModifySelection(_ sender: Any?) {
        pageDown(sender)
    }

    open override func scrollPageDown(_ sender: Any?) {
        scroll(visibleRect.moved(dy: visibleRect.height).origin)
    }

    open override func scrollPageUp(_ sender: Any?) {
        scroll(visibleRect.moved(dy: -visibleRect.height).origin)
    }

    open override func scrollToBeginningOfDocument(_ sender: Any?) {
        scroll(CGPoint(x: visibleRect.origin.x, y: frame.minY))
    }

    open override func scrollToEndOfDocument(_ sender: Any?) {
        scroll(CGPoint(x: visibleRect.origin.x, y: frame.maxY))
    }
}
