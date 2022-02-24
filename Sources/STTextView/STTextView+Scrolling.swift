//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    public override func centerSelectionInVisibleArea(_ sender: Any?) {
        guard !textLayoutManager.textSelections.isEmpty else {
            return
        }

        scrollToSelection(textLayoutManager.textSelections[0])
        needsDisplay = true
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

    internal func scrollToSelection(_ selection: NSTextSelection) {
        guard let selectionTextRange = selection.textRanges.first else {
            return
        }

        if selectionTextRange.isEmpty {
            if let textLayoutFragment = textLayoutManager.textLayoutFragment(for: selectionTextRange.location) {
                scrollToVisible(textLayoutFragment.layoutFragmentFrame)
            }
        } else {
            switch selection.affinity {
            case .upstream:
                if let textLayoutFragment = textLayoutManager.textLayoutFragment(for: selectionTextRange.location) {
                    scrollToVisible(textLayoutFragment.layoutFragmentFrame)
                }
            case .downstream:
                if let location = textLayoutManager.location(selectionTextRange.endLocation, offsetBy: -1),
                   let textLayoutFragment = textLayoutManager.textLayoutFragment(for: location)
                {
                    self.scrollToVisible(textLayoutFragment.layoutFragmentFrame)
                }
            @unknown default:
                break
            }
        }
    }
    
}
