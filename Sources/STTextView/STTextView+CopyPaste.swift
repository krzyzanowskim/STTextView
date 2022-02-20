//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    @objc func copy(_ sender: Any?) {
        if textLayoutManager.textSelections.isEmpty, let documentString = textContentStorage.attributedString?.string, !documentString.isEmpty {
            updatePasteboard(with: documentString)
        } else if !textLayoutManager.textSelections.isEmpty {
            if let textSelectionsString = textLayoutManager.textSelectionsString(), !textSelectionsString.isEmpty {
                updatePasteboard(with: textSelectionsString)
            }
        }
    }

    @objc func paste(_ sender: Any?) {
        guard let string = NSPasteboard.general.string(forType: .string) else {
            return
        }

        let insertLocation = textLayoutManager.insertionPointLocation ?? textLayoutManager.documentRange.location
        let nsrange = NSRange(insertLocation, in: textContentStorage)
        insertText(string, replacementRange: nsrange)
    }

    @objc func cut(_ sender: Any?) {
        copy(sender)
        delete(sender)
    }

    @objc func delete(_ sender: Any?) {
        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
            // "replaceContents" doesn't work with NSTextContentStorage at all
            // textLayoutManager.replaceContents(in: textRange, with: NSAttributedString())
            let nsrange = NSRange(textRange, in: textContentStorage)
            insertText("", replacementRange: nsrange)
        }
    }

    private func updatePasteboard(with text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([text as NSPasteboardWriting])
    }
}
