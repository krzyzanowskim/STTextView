//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import UniformTypeIdentifiers

extension STTextView {

    @objc open func copy(_ sender: Any?) {
        if textLayoutManager.textSelections.isEmpty, let attributedString = textContentManager.attributedString(in: nil) {
            updatePasteboard(with: attributedString)
        } else if !textLayoutManager.textSelections.isEmpty {
            if let textSelectionsAttributedString = textLayoutManager.textSelectionsAttributedString() {
                updatePasteboard(with: textSelectionsAttributedString)
            }
        }
    }

    @objc open func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        if pasteboard.canReadItem(withDataConformingToTypes: [UTType.rtf.identifier]), let attributedString = pasteboard.readObjects(forClasses: [NSAttributedString.self])?.first as? NSAttributedString {
            replaceCharacters(
                in: textLayoutManager.textSelections.flatMap(\.textRanges),
                with: attributedString,
                allowsTypingCoalescing: false
            )
        } else if pasteboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]), let string = pasteboard.string(forType: .string) {
            replaceCharacters(
                in: textLayoutManager.textSelections.flatMap(\.textRanges),
                with: string,
                useTypingAttributes: true,
                allowsTypingCoalescing: false
            )
        }
    }

    @objc func pasteAsPlainText(_ sender: Any?) {
        guard let string = NSPasteboard.general.string(forType: .string) else {
            return
        }

        replaceCharacters(
            in: textLayoutManager.textSelections.flatMap(\.textRanges),
            with: string,
            useTypingAttributes: true,
            allowsTypingCoalescing: false
        )
    }

    @objc open func cut(_ sender: Any?) {
        copy(sender)
        delete(sender)
    }

    @objc open func delete(_ sender: Any?) {
        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
            // "replaceContents" doesn't work with NSTextContentStorage at all
            // textLayoutManager.replaceContents(in: textRange, with: NSAttributedString())
            let nsrange = NSRange(textRange, in: textContentManager)
            insertText("", replacementRange: nsrange)
        }
    }

    private func updatePasteboard(with text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([text as NSPasteboardWriting])
    }

    private func updatePasteboard(with text: NSAttributedString) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([text as NSPasteboardWriting])
    }
}
