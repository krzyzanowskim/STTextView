//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    /// This action method changes the font of the selection for a rich text object, or of all text for a plain text object.
    @objc public func changeFont(_ sender: Any?) {
        guard isEditable, usesFontPanel, let fontManager = sender as? NSFontManager else {
            return
        }

        if let currentTypingFont = typingAttributes[.font] as? NSFont {
            let newFont = fontManager.convert(currentTypingFont)
            if !textLayoutManager.insertionPointLocations.isEmpty {
                typingAttributes[.font] = newFont
            }
        }

        // FB9692714: if rendering attribute would work, use this: textLayoutManager.enumerateRenderingAttributes(from: , reverse: , using: )
        // Assumption: self.attributedString map 1:1 with the storage range. May or may not be true all the time (I can imagine it won't)
        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) where !textRange.isEmpty {
            let selectionNSRange = NSRange(textRange, in: textContentManager)
            attributedString().enumerateAttribute(.font, in: selectionNSRange, options: []) { value, runRange, stop in
                if let currentFont = value as? NSFont {
                    if let runTextRange = NSTextRange(runRange, in: textContentManager) {
                        let newFont = fontManager.convert(currentFont)
                        addAttributes([.font: newFont], range: runTextRange)
                    }
                }
            }
        }
    }
}
