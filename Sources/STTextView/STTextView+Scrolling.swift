//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    public override func centerSelectionInVisibleArea(_ sender: Any?) {
        assertionFailure()
    }

    public override func pageUp(_ sender: Any?) {
        assertionFailure()
    }

    public override func pageUpAndModifySelection(_ sender: Any?) {
        assertionFailure()
    }

    public override func pageDown(_ sender: Any?) {
        assertionFailure()
    }

    public override func pageDownAndModifySelection(_ sender: Any?) {
        assertionFailure()
    }

}

extension STTextView {

    func scrollToVisibleInsertionPointLocation() {
        if let insertionPointLocation = textLayoutManager.insertionPointLocation,
           let textLayoutFragment = textLayoutManager.textLayoutFragment(for: insertionPointLocation)
        {
            scrollToVisible(textLayoutFragment.layoutFragmentFrame)
            needsDisplay = true
        }
    }

}
