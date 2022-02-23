//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {

    public override func yank(_ sender: Any?) {
        cut(sender)
    }

    public override func deleteForward(_ sender: Any?) {
        let textRanges = textLayoutManager.textSelections.flatMap { textSelection in
            textLayoutManager.textSelectionNavigation.deletionRanges(
                for: textSelection,
                direction: .forward,
                destination: .character,
                allowsDecomposition: false
            )
        }

        if textRanges.isEmpty {
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

        needsViewportLayout = true
        needsDisplay = true
        didChangeText()
    }

    public override func deleteBackward(_ sender: Any?) {
        let textRanges = textLayoutManager.textSelections.flatMap { textSelection in
            textLayoutManager.textSelectionNavigation.deletionRanges(
                for: textSelection,
                direction: .backward,
                destination: .character,
                allowsDecomposition: false
            )
        }

        if textRanges.isEmpty {
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
        
        needsViewportLayout = true
        needsDisplay = true
        didChangeText()
    }
}
