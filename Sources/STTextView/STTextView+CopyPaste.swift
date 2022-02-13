//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    @objc func copy(_ sender: Any?) {
        
    }

    @objc func paste(_ sender: Any?) {

    }

    @objc func cut(_ sender: Any?) {

    }

    @objc func delete(_ sender: Any?) {

    }

    private func updatePasteboard(with text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([text as NSPasteboardWriting])
    }
}
