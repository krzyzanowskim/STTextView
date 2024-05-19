//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import UniformTypeIdentifiers

extension STTextView {

    @objc open func copy(_ sender: Any?) {
        _ = writeSelection(to: NSPasteboard.general, types: [.rtf, .string])
    }

    @objc open func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general

        if pasteboard.canReadItem(withDataConformingToTypes: [UTType.rtf.identifier]) {
            pasteAsRichText(sender)
        } else if pasteboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]) {
            pasteAsPlainText(sender)
        }
    }

    @objc open func pasteAsPlainText(_ sender: Any?) {
        _ = readSelection(from: NSPasteboard.general, type: .string)
    }

    /// This action method inserts the contents of the pasteboard into the receiver’s text as rich text, maintaining its attributes.
    @objc open func pasteAsRichText(_ sender: Any?) {
        _ = readSelection(from: NSPasteboard.general, type: .rtf)
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
}
