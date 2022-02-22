//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    public override func insertLineBreak(_ sender: Any?) {
        insertNewline(sender)
    }

    public override func insertTab(_ sender: Any?) {
        insertText("\t")
    }

    public override func insertNewline(_ sender: Any?) {
        insertText("\n")
    }

    public override func insertText(_ insertString: Any) {
        insertText(insertString, replacementRange: NSRange.notFound)
    }


//     public override func doCommand(by selector: Selector) {
//        print(selector)
//        super.doCommand(by: selector)
//     }
}
