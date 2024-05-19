//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    open override func insertLineBreak(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSLineSeparatorCharacter) else {
            assertionFailure()
            return
        }

        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    open override func insertTab(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSTabCharacter) else {
            assertionFailure()
            return
        }
        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    open override func insertBacktab(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSBackTabCharacter) else {
            assertionFailure()
            return
        }
        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    open override func insertTabIgnoringFieldEditor(_ sender: Any?) {
        insertTab(sender)
    }

    open override func insertParagraphSeparator(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSParagraphSeparatorCharacter) else {
            assertionFailure()
            return
        }
        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    open override func insertNewline(_ sender: Any?) {
        // insert newline with current typing attributes
        breakUndoCoalescing()
        insertText("\n")
        breakUndoCoalescing()
    }

    open override func insertNewlineIgnoringFieldEditor(_ sender: Any?) {
        insertNewline(sender)
    }

    open override func insertText(_ insertString: Any) {
        insertText(insertString, replacementRange: .notFound)
    }

}
