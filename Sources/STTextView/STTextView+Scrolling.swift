//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    open override func centerSelectionInVisibleArea(_ sender: Any?) {
        guard !textLayoutManager.textSelections.isEmpty else {
            return
        }

        scrollToSelection(textLayoutManager.textSelections[0])
        needsDisplay = true
    }

    open override func pageUp(_ sender: Any?) {
        assertionFailure()
    }

    open override func pageUpAndModifySelection(_ sender: Any?) {
        assertionFailure()
    }

    open override func pageDown(_ sender: Any?) {
        assertionFailure()
    }

    open override func pageDownAndModifySelection(_ sender: Any?) {
        assertionFailure()
    }

}
