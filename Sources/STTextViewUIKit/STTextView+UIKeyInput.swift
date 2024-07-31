//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension STTextView: UIKeyInput {

    public var hasText: Bool {
        !textContentManager.documentRange.isEmpty
    }

    public func insertText(_ text: String) {
        let textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
        if shouldChangeText(in: textRanges, replacementString: text) {
            inputDelegate?.selectionWillChange(self)
            replaceCharacters(in: textRanges, with: text, useTypingAttributes: true, allowsTypingCoalescing: true)
            inputDelegate?.selectionDidChange(self)
        }
    }

    public func deleteBackward() {
        let textRanges = textLayoutManager.textSelections.flatMap { textSelection -> [NSTextRange] in
            textLayoutManager.textSelectionNavigation.deletionRanges(
                for: textSelection,
                direction: .backward,
                destination: .character,
                allowsDecomposition: false
            )
        }

        if textRanges.isEmpty || !shouldChangeText(in: textRanges, replacementString: "") {
            return
        }

        inputDelegate?.selectionWillChange(self)
        replaceCharacters(in: textRanges, with: "", useTypingAttributes: false, allowsTypingCoalescing: true)
        inputDelegate?.selectionDidChange(self)
    }

}
