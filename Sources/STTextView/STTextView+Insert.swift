//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    open override func insertLineBreak(_ sender: Any?) {
        insertNewline(sender)
    }

    open override func insertTab(_ sender: Any?) {
        insertText("\t")
    }

    open override func insertNewline(_ sender: Any?) {
        insertText("\n")
    }

    open override func insertText(_ insertString: Any) {
        insertText(insertString, replacementRange: NSRange.notFound)
    }

}
