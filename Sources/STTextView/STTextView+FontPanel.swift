//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    /// This action method changes the font of the selection for a rich text object, or of all text for a plain text object.
    @objc open func changeFont(_ sender: Any?) {
        guard isEditable, usesFontPanel, let fontManager = sender as? NSFontManager else {
            return
        }

        if let currentTypingFont = typingAttributes[.font] as? NSFont {
            let newFont = fontManager.convert(currentTypingFont)
            if !textLayoutManager.insertionPointLocations.isEmpty {
                typingAttributes[.font] = newFont
            }
        }

        // Assumption: self.attributedString map 1:1 with the storage range. May or may not be true all the time (I can imagine it won't)
        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) where !textRange.isEmpty {
            guard let attributedStringInRange = textContentManager.attributedString(in: textRange) else {
                return
            }

            let selectionNSRange = NSRange(textRange, in: textContentManager)
            for (runRange, value) in attributedStringInRange.attribute(.font, in: attributedStringInRange.range, options: .longestEffectiveRangeNotRequired) {
                guard let currentFont = value as? NSFont else {
                    return
                }

                let documentScopeRange = NSRange(location: selectionNSRange.location + runRange.location, length: runRange.length)
                guard let runTextRange = NSTextRange(documentScopeRange, in: textContentManager) else {
                    return
                }

                let newFont = fontManager.convert(currentFont)
                addAttributes([.font: newFont], range: runTextRange)
            }
        }
    }

    @objc open func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        [.collection, .face, .size]
    }
}
