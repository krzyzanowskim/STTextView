//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    /// The mark is a saved selection that later commands can select to, swap with, or kill to.
    /// Together with `yank(_:)` it completes the Emacs-style command family from
    /// `NSStandardKeyBindingResponding`, which multi-step `DefaultKeyBinding.dict`
    /// macros (line moves, paragraph cut/copy, …) are commonly built on.
    ///
    /// https://www.gnu.org/software/emacs/manual/html_node/emacs/Setting-Mark.html
    override open func setMark(_ sender: Any?) {
        _mark = textSelection
    }

    /// Exchanges the current selection with the mark, so the two locations can be toggled between.
    override open func swapWithMark(_ sender: Any?) {
        guard let mark = clampedMark() else { return }
        _mark = textSelection
        textSelection = mark
    }

    /// Extends the selection to cover everything between the mark and the current selection.
    override open func selectToMark(_ sender: Any?) {
        guard let mark = clampedMark() else { return }
        textSelection = NSUnionRange(mark, textSelection)
    }

    /// Deletes everything between the mark and the current selection, adding it to the kill ring
    /// (routed through `deleteBackward(_:)`, which feeds `_yankingManager`) so a following
    /// `yank(_:)` reinserts it.
    override open func deleteToMark(_ sender: Any?) {
        guard let mark = clampedMark() else { return }
        textSelection = NSUnionRange(mark, textSelection)
        deleteBackward(sender)
        _mark = textSelection
    }

    /// The mark survives arbitrary edits, so by the time it's used it can point past the current
    /// text end (or into it with excess length).
    private func clampedMark() -> NSRange? {
        guard let mark = _mark else { return nil }
        let length = textContentManager.length
        let location = min(mark.location, length)
        return NSRange(location: location, length: min(mark.length, length - location))
    }
}
