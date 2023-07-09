//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    open override func deleteForward(_ sender: Any?) {
        if let deletedString = delete(direction: .forward, destination: .character, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .delete, string: deletedString)
        }
    }

    open override func deleteBackward(_ sender: Any?) {
        if let deletedString = delete(direction: .backward, destination: .character, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .delete, string: deletedString)
        }
    }

    open override func deleteBackwardByDecomposingPreviousCharacter(_ sender: Any?) {
        if let deletedString = delete(direction: .backward, destination: .character, allowsDecomposition: true) {
            YankingManager.shared.kill(action: .delete, string: deletedString)
        }
    }

    open override func deleteWordBackward(_ sender: Any?) {
        if let deletedString = delete(direction: .backward, destination: .word, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .deleteWordBackward, string: deletedString)
        }
    }

    open override func deleteWordForward(_ sender: Any?) {
        if let deletedString = delete(direction: .forward, destination: .word, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .deleteWordForward, string: deletedString)
        }
    }

    open override func deleteToBeginningOfLine(_ sender: Any?) {
        if let deletedString = delete(direction: .backward, destination: .line, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .deleteToBeginningOfLine, string: deletedString)
        }
    }

    open override func deleteToEndOfLine(_ sender: Any?) {
        if let deletedString = delete(direction: .forward, destination: .line, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .deleteToEndOfLine, string: deletedString)
        }
    }

    open override func deleteToBeginningOfParagraph(_ sender: Any?) {
        if let deletedString = delete(direction: .backward, destination: .paragraph, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .deleteToBeginningOfLine, string: deletedString)
        }
    }

    open override func deleteToEndOfParagraph(_ sender: Any?) {
        if let deletedString = delete(direction: .forward, destination: .paragraph, allowsDecomposition: false) {
            YankingManager.shared.kill(action: .deleteToEndOfParagraph, string: deletedString)
        }
    }

    @discardableResult
    private func delete(direction: NSTextSelectionNavigation.Direction, destination: NSTextSelectionNavigation.Destination, allowsDecomposition: Bool) -> String? {
        let textRanges = textLayoutManager.textSelections.flatMap { textSelection -> [NSTextRange] in
            if destination == .word {
                // FB9925766. deletionRanges only works correctly if textSelection is at the end of the word
                // Workaround
                return textLayoutManager.textSelectionNavigation.destinationSelection(
                    for: textSelection,
                    direction: direction,
                    destination: destination,
                    extending: true,
                    confined: false
                )?.textRanges ?? []
            } else {
                return textLayoutManager.textSelectionNavigation.deletionRanges(
                    for: textSelection,
                    direction: direction,
                    destination: destination,
                    allowsDecomposition: allowsDecomposition
                )
            }
        }

        if textRanges.isEmpty || !shouldChangeText(in: textRanges, replacementString: nil) {
            return nil
        }

        let deletedString = textRanges.reduce(into: "") { partialResult, textRange in
            partialResult += textLayoutManager.substring(for: textRange) ?? ""
        }

        replaceCharacters(in: textRanges, with: "", useTypingAttributes: false, allowsTypingCoalescing: true)
        return deletedString
    }
}
