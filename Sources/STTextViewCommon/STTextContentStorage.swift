//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

import STTextKitPlus

package final class STTextContentStorage: NSTextContentStorage {

    package override func replaceContents(in range: NSTextRange, with textElements: [NSTextElement]?) {
        assert(hasEditingTransaction, "Not called inside performEditingTransaction")

        guard let textStorage = textStorage,
              let attributedTextElements = textElements?.compactMap({ $0 as? STAttributedTextElement })
        else {
            // Non-functional (FB9925647)
            super.replaceContents(in: range, with: textElements)
            assertionFailure()
            return
        }

        let replacementString = NSMutableAttributedString()
        replacementString.beginEditing()
        for attributedTextElement in attributedTextElements {
            replacementString.append(attributedTextElement.attributedString)
        }
        replacementString.endEditing()

        // Replace text and (unexpectedly) reset textSelections in
        // -[NSTextLayoutManager _fixSelectionAfterChangeInCharacterRange:changeInLength:]
        // that breaks multi cursor setup
        // Workaround: Fix _fixSelectionAfterChangeInCharacterRange nad fix selection by myself

        textStorage.beginEditing()
        textStorage.replaceCharacters(
            in: NSRange(range, in: self),
            with: replacementString
        )
        textStorage.endEditing()

        fix_fixSelectionAfterChangeInCharacterRange()
    }

    // Fix a result of the NSTextLayoutManager._fixSelectionAfterChangeInCharacterRange
    // specifically: duplicated (identical) ranges and selections
    private func fix_fixSelectionAfterChangeInCharacterRange() {
        // Remove duplicated selections that are result of _fixSelectionAfterChangeInCharacterRange
        for textLayoutManager in textLayoutManagers {
            let origSelections = textLayoutManager.textSelections
            var uniqueSelections: [NSTextSelection] = []
            uniqueSelections.reserveCapacity(origSelections.count)

            // Remove duplicated selections
            for selection in origSelections {
                if !uniqueSelections.contains(where: { $0.textRanges == selection.textRanges }) {
                    uniqueSelections.append(selection)
                }
            }

            // Remove duplicated textRanges in selections
            var finalSelections: [NSTextSelection] = []
            finalSelections.reserveCapacity(uniqueSelections.count)
            for selection in uniqueSelections {

                var uniqueRanges: [NSTextRange] = []
                uniqueRanges.reserveCapacity(selection.textRanges.count)
                for textRange in selection.textRanges {
                    if !uniqueRanges.contains(where: { $0 == textRange }) {
                        uniqueRanges.append(textRange)
                    }
                }

                let selectionCopy = NSTextSelection(uniqueRanges, affinity: selection.affinity, granularity: selection.granularity)
                selectionCopy.anchorPositionOffset = selection.anchorPositionOffset
                selectionCopy.isLogical = selection.isLogical
                selectionCopy.typingAttributes = selection.typingAttributes
                finalSelections.append(selectionCopy)
            }

            textLayoutManager.textSelections = finalSelections
        }
    }

    // override func enumerateTextElements(from textLocation: NSTextLocation?, options: NSTextContentManager.EnumerationOptions = [], using block: (NSTextElement) -> Bool) -> NSTextLocation? {
    //     super.enumerateTextElements(from: textLocation, options: options, using: block)
    // }
    //
    // override func recordEditAction(in originalTextRange: NSTextRange, newTextRange: NSTextRange) {
    //     super.recordEditAction(in: originalTextRange, newTextRange: newTextRange)
    // }
}
