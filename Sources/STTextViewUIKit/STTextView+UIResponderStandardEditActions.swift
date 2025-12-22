//
//  STTextView+UIResponderStandardEditActions.swift
//
//
//  Created by Marcin Krzyzanowski on 31/07/2024.
//

import Foundation
import UIKit

// UIResponderStandardEditActions
extension STTextView {

    @objc override open func copy(_ sender: Any?) {
        if let selectedTextRange, let text = text(in: selectedTextRange) {
            UIPasteboard.general.string = text
        }
    }

    @objc override open func paste(_ sender: Any?) {
        if let selectedTextRange, let string = UIPasteboard.general.string {
            inputDelegate?.selectionWillChange(self)
            replace(selectedTextRange, withText: string)
            inputDelegate?.selectionDidChange(self)
        }
    }

//    @objc open override func pasteAndGo(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.pasteAndGo(sender)
//    }
//
//    @objc open override func pasteAndSearch(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.pasteAndSearch(sender)
//    }
//
//    @objc open override func pasteAndMatchStyle(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.pasteAndMatchStyle(sender)
//    }

    @objc override open func cut(_ sender: Any?) {
        if let selectedTextRange, let text = text(in: selectedTextRange) {
            UIPasteboard.general.string = text
            replace(selectedTextRange, withText: "")
        }
    }

    @objc override open func delete(_ sender: Any?) {
        if let selectedTextRange {
            inputDelegate?.selectionWillChange(self)
            replace(selectedTextRange, withText: "")
            inputDelegate?.selectionDidChange(self)
        }
    }

    /// When autocorrection is enabled and the user tap on a misspelled word, UITextInteraction will present
    /// a UIMenuController with suggestions for the correct spelling of the word. Selecting a suggestion will
    /// cause UITextInteraction to call the non-existing -replace(:) function and pass an instance of the private
    /// UITextReplacement type as parameter. We can't make autocorrection work properly without using private API.
    ///
    /// Copied from @simonbs/Runestone
    @objc open func replace(_ obj: NSObject) {
        if let replacementText = obj.value(forKey: "_repl" + "Ttnemeca".reversed() + "ext") as? String {
            if let indexedRange = obj.value(forKey: "_r" + "gna".reversed() + "e") as? STTextLocationRange {
                replace(indexedRange, withText: replacementText)
            }
        }
    }

    /// Selects the content in your responder.
    ///
    /// UIKit calls this method when the user selects the Select command from an editing menu.
    /// The command is used for the targeted selection of content in a view.
    /// For example, a text view uses this to select one or more words in the view and to display the selection interface.
    @objc override open func select(_ sender: Any?) {
        if let selectedTextRange {
            let positionSelection = NSTextSelection(range: selectedTextRange.nsTextRange, affinity: .downstream, granularity: .word)

            let destinationBackward = textLayoutManager.textSelectionNavigation.destinationSelection(
                for: positionSelection,
                direction: .backward,
                destination: .word,
                extending: true,
                confined: true
            )

            let destinationForward = textLayoutManager.textSelectionNavigation.destinationSelection(
                for: positionSelection,
                direction: .forward,
                destination: .word,
                extending: true,
                confined: true
            )

            if let textRange = destinationBackward?.textRanges.first, !textRange.isEmpty {
                self.selectedTextRange = textRange.uiTextRange
            } else if let textRange = destinationForward?.textRanges.first, !textRange.isEmpty {
                self.selectedTextRange = textRange.uiTextRange
            }
        }
    }

    @objc override open func selectAll(_ sender: Any?) {
        guard isSelectable else {
            return
        }

        inputDelegate?.selectionWillChange(self)

        textLayoutManager.textSelections = [
            NSTextSelection(range: textLayoutManager.documentRange, affinity: .downstream, granularity: .line)
        ]

        updateTypingAttributes()
        updateSelectedLineHighlight()
        layoutGutter()

        setNeedsLayout()
        inputDelegate?.selectionDidChange(self)
    }

//    @objc open override func toggleItalics(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.toggleItalics(sender)
//    }
//
//    @objc open override func toggleBoldface(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.toggleBoldface(sender)
//    }
//
//    @objc open override func toggleUnderline(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.toggleUnderline(sender)
//    }

//    @objc open override func increaseSize(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.increaseSize(sender)
//    }
//
//    @objc open override func decreaseSize(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.decreaseSize(sender)
//    }

//    @objc open override func updateTextAttributes(conversionHandler: ([NSAttributedString.Key : Any]) -> [NSAttributedString.Key : Any]) {
//        assertionFailure("Not implemented")
//        return super.updateTextAttributes(conversionHandler: conversionHandler)
//    }

//    @objc open override func makeTextWritingDirectionLeftToRight(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.makeTextWritingDirectionLeftToRight(sender)
//    }
//
//    @objc open override func makeTextWritingDirectionRightToLeft(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.makeTextWritingDirectionRightToLeft(sender)
//    }

//    @objc open override func printContent(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.printContent(sender)
//    }

//    @objc open override func find(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.find(sender)
//    }
//
//    @objc open override func findNext(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.findNext(sender)
//    }
//
//    @objc open override func findPrevious(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.findPrevious(sender)
//    }
//
//    @objc open override func findAndReplace(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.findAndReplace(sender)
//    }
//
//    @objc open override func useSelectionForFind(_ sender: Any?) {
//        assertionFailure("Not implemented")
//        super.useSelectionForFind(sender)
//    }
}
