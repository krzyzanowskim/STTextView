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

extension STTextView {
    
    public func insertText(_ string: Any, replacementRange: NSRange) {
        guard isEditable else { return }

        switch string {
        case is String:
            guard let string = string as? String else {
                return
            }
            if let textRange = NSTextRange(replacementRange, in: textContentStorage) {
                let nsrange = NSRange(textRange, in: textContentStorage)
                if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string) ?? true {
                    textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                    needsViewportLayout = true
                    didChangeText()
                }
            } else if !textLayoutManager.textSelections.isEmpty {
                textContentStorage.textStorage?.beginEditing()
                for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
                    let nsrange = NSRange(textRange, in: textContentStorage)
                    if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string) ?? true {
                        textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                        needsViewportLayout = true
                        didChangeText()
                    }
                }
                textContentStorage.textStorage?.endEditing()
                scrollToVisibleInsertionPointLocation()
            }
        case is NSAttributedString:
            guard let string = string as? NSAttributedString else {
                return
            }
            if let textRange = NSTextRange(replacementRange, in: textContentStorage) {
                let nsrange = NSRange(textRange, in: textContentStorage)
                if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string.string) ?? true {
                    textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                    needsViewportLayout = true
                    didChangeText()
                }
            } else if !textLayoutManager.textSelections.isEmpty {
                textContentStorage.textStorage?.beginEditing()
                for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
                    let nsrange = NSRange(textRange, in: textContentStorage)
                    if delegate?.textView?(self, shouldChangeTextIn: nsrange, replacementString: string.string) ?? true {
                        textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: string)
                        needsViewportLayout = true
                        didChangeText()
                    }
                }
                textContentStorage.textStorage?.endEditing()
                scrollToVisibleInsertionPointLocation()
            }
        default:
            assertionFailure()
        }
    }
}
