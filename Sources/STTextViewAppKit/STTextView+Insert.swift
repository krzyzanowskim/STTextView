//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    override open func insertLineBreak(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSLineSeparatorCharacter) else {
            assertionFailure()
            return
        }

        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    override open func insertTab(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSTabCharacter) else {
            assertionFailure()
            return
        }
        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    override open func insertBacktab(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSBackTabCharacter) else {
            assertionFailure()
            return
        }
        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    override open func insertTabIgnoringFieldEditor(_ sender: Any?) {
        insertTab(sender)
    }

    override open func insertParagraphSeparator(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSParagraphSeparatorCharacter) else {
            assertionFailure()
            return
        }
        insertText(String(Character(scalar)), replacementRange: .notFound)
    }

    override open func insertNewline(_ sender: Any?) {
        guard let scalar = Unicode.Scalar(NSNewlineCharacter) else {
            assertionFailure()
            return
        }
        // insert newline with current typing attributes
        breakUndoCoalescing()
        insertText(String(Character(scalar)))
        breakUndoCoalescing()
    }

    override open func insertNewlineIgnoringFieldEditor(_ sender: Any?) {
        insertNewline(sender)
    }

    override open func insertText(_ insertString: Any) {
        insertText(insertString, replacementRange: .notFound)
    }

}
