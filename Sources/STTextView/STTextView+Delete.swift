//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    public override func yank(_ sender: Any?) {
        cut(sender)
    }

    public override func deleteForward(_ sender: Any?) {
        delete(direction: .forward, destination: .character, allowsDecomposition: false)
    }

    public override func deleteBackward(_ sender: Any?) {
        delete(direction: .backward, destination: .character, allowsDecomposition: false)
    }

    public override func deleteBackwardByDecomposingPreviousCharacter(_ sender: Any?) {
        delete(direction: .backward, destination: .character, allowsDecomposition: true)
    }

    public override func deleteWordBackward(_ sender: Any?) {
        delete(direction: .backward, destination: .word, allowsDecomposition: false)
    }

    public override func deleteWordForward(_ sender: Any?) {
        delete(direction: .forward, destination: .word, allowsDecomposition: false)
    }

    public override func deleteToBeginningOfLine(_ sender: Any?) {
        delete(direction: .backward, destination: .line, allowsDecomposition: false)
    }

    public override func deleteToEndOfLine(_ sender: Any?) {
        delete(direction: .forward, destination: .line, allowsDecomposition: false)
    }

    public override func deleteToBeginningOfParagraph(_ sender: Any?) {
        delete(direction: .backward, destination: .paragraph, allowsDecomposition: false)
    }

    public override func deleteToEndOfParagraph(_ sender: Any?) {
        delete(direction: .forward, destination: .paragraph, allowsDecomposition: false)
    }

    private func delete(direction: NSTextSelectionNavigation.Direction, destination: NSTextSelectionNavigation.Destination, allowsDecomposition: Bool) {
        let textRanges = textLayoutManager.textSelections.flatMap { textSelection -> [NSTextRange] in
            if direction == .backward && destination == .word {
                // FB9925766. deletionRanges only works correctly if textSelection is at the end of the word
                // Workaround
                return textLayoutManager.textSelectionNavigation.destinationSelection(
                    for: textSelection,
                    direction: .backward,
                    destination: .word,
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

        if textRanges.isEmpty || textRanges == textLayoutManager.textSelections.flatMap(\.textRanges) {
            return
        }

        textContentStorage.performEditingTransaction {
            for textRange in textRanges {
                let range = NSRange(textRange, in: textContentStorage)
                if delegate?.textView?(self, shouldChangeTextIn: range, replacementString: nil) ?? true {
                    textContentStorage.textStorage?.deleteCharacters(in: range)
                }
            }
        }

        didChangeText()
    }
}
