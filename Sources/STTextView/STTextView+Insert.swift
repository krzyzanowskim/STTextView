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


//     public override func doCommand(by selector: Selector) {
//        print(selector)
//        super.doCommand(by: selector)
//     }
}

extension STTextView {
    
    open func insertText(_ string: Any, replacementRange: NSRange) {
        guard isEditable else { return }
        var didChange = false

        textContentStorage.performEditingTransaction {
            switch string {
            case is String:
                guard let string = string as? String else {
                    return
                }
                if let textRange = NSTextRange(replacementRange, in: textContentStorage) {
                    let nsrange = NSRange(textRange, in: textContentStorage)
                    if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string) ?? true {
                        textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                        didChange = true
                    }
                } else if !textLayoutManager.textSelections.isEmpty {
                    for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
                        let nsrange = NSRange(textRange, in: textContentStorage)
                        if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string) ?? true {
                            textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                            didChange = true
                        }
                    }
                }
            case is NSAttributedString:
                guard let string = string as? NSAttributedString else {
                    return
                }
                if let textRange = NSTextRange(replacementRange, in: textContentStorage) {
                    let nsrange = NSRange(textRange, in: textContentStorage)
                    if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string.string) ?? true {
                        textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                        didChange = true
                    }
                } else if !textLayoutManager.textSelections.isEmpty {
                    for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
                        let nsrange = NSRange(textRange, in: textContentStorage)
                        if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string.string) ?? true {
                            textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                            didChange = true
                        }
                    }
                }
            default:
                assertionFailure()
            }

        }

        if didChange {
            didChangeText()
        }
    }
}
