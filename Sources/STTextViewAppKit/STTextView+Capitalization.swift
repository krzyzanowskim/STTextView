//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    open override func capitalizeWord(_ sender: Any?) {
        guard isEditable else {
            return
        }

        selectWord(sender)

        // capitalize attributed string without loosing attributes
        let selectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
        for selectionRange in selectionRanges {
            if let attributedString = textLayoutManager.textAttributedString(in: selectionRange) {
                replaceCharacters(in: selectionRange, with: attributedString.string.localizedCapitalized)
            }
        }

        // select updated ranges
        textLayoutManager.textSelections = selectionRanges.map {
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .word,
                enclosing: NSTextSelection($0.location, affinity: .upstream)
            )
        }

    }

    open override func lowercaseWord(_ sender: Any?) {
        guard isEditable else {
            return
        }

        selectWord(sender)

        // capitalize attributed string without loosing attributes
        let selectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
        for selectionRange in selectionRanges {
            if let attributedString = textLayoutManager.textAttributedString(in: selectionRange) {
                replaceCharacters(in: selectionRange, with: attributedString.string.localizedLowercase)
            }
        }

        // select updated ranges
        textLayoutManager.textSelections = selectionRanges.map {
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .word,
                enclosing: NSTextSelection($0.location, affinity: .upstream)
            )
        }
    }

    open override func uppercaseWord(_ sender: Any?) {
        guard isEditable else {
            return
        }

        selectWord(sender)

        // capitalize attributed string without loosing attributes
        let selectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
        for selectionRange in selectionRanges {
            if let attributedString = textLayoutManager.textAttributedString(in: selectionRange) {
                replaceCharacters(in: selectionRange, with: attributedString.string.localizedUppercase)
            }
        }

        // select updated ranges
        textLayoutManager.textSelections = selectionRanges.map {
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .word,
                enclosing: NSTextSelection($0.location, affinity: .upstream)
            )
        }
    }
}
