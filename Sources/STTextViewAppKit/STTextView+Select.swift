//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView {

    internal func setSelectedTextRange(_ textRange: NSTextRange, updateLayout: Bool) {
        guard isSelectable, textRange.endLocation <= textLayoutManager.documentRange.endLocation else {
            return
        }

        textLayoutManager.textSelections = [
            NSTextSelection(range: textRange, affinity: .downstream, granularity: .character)
        ]

        updateTypingAttributes(at: textRange.location)

        if updateLayout {
            needsLayout = true
        }
    }

    internal func setSelectedRange(_ range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }
        setSelectedTextRange(textRange, updateLayout: true)
    }
    
    open override func selectAll(_ sender: Any?) {
        
        guard isSelectable else {
            return
        }

        textLayoutManager.textSelections = [
            NSTextSelection(range: textLayoutManager.documentRange, affinity: .downstream, granularity: .line)
        ]

        updateTypingAttributes()
        updateSelectedRangeHighlight()
        layoutGutter()
        updateSelectedLineHighlight()
    }

    open override func selectLine(_ sender: Any?) {
        guard isSelectable, let enclosingSelection = textLayoutManager.textSelections.last else {
            return
        }

        textLayoutManager.textSelections = [
            textLayoutManager.textSelectionNavigation.textSelection(
                    for: .line,
                    enclosing: enclosingSelection
                )
        ]

        updateTypingAttributes()
        needsScrollToSelection = true
        needsDisplay = true
    }

    open override func selectWord(_ sender: Any?) {
        guard isSelectable, let enclosingSelection = textLayoutManager.textSelections.last else {
            return
        }

        textLayoutManager.textSelections = [
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .word,
                enclosing: enclosingSelection
            )
        ]

        updateTypingAttributes()
        needsScrollToSelection = true
        needsDisplay = true
    }

    open override func selectParagraph(_ sender: Any?) {
        guard isSelectable, let enclosingSelection = textLayoutManager.textSelections.last else {
            return
        }

        textLayoutManager.textSelections = [
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .paragraph,
                enclosing: enclosingSelection
            )
        ]

        updateTypingAttributes()
        needsScrollToSelection = true
        needsDisplay = true

    }

    open override func moveLeft(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    open override func moveLeftAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    open override func moveRight(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    open override func moveRightAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    open override func moveUp(_ sender: Any?) {
        setTextSelections(
            direction: .up,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    open override func moveUpAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .up,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    open override func moveDown(_ sender: Any?) {
        setTextSelections(
            direction: .down,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    open override func moveDownAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .down,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    open override func moveForward(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    open override func moveForwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    open override func moveBackward(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    open override func moveBackwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    open override func moveWordLeft(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    open override func moveWordLeftAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    open override func moveWordRight(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    open override func moveWordRightAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    open override func moveWordForward(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    open override func moveWordForwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    open override func moveWordBackward(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    open override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    open override func moveToBeginningOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    open override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    open override func moveToLeftEndOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    open override func moveToLeftEndOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    open override func moveToEndOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    open override func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    open override func moveToRightEndOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    open override func moveToRightEndOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    open override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .paragraph,
            extending: true,
            confined: false
        )
    }

    open override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .paragraph,
            extending: true,
            confined: false
        )
    }

    open override func moveToBeginningOfParagraph(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .paragraph,
            extending: false,
            confined: true
        )
    }

    open override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .paragraph,
            extending: true,
            confined: true
        )
    }

    open override func moveToEndOfParagraph(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .paragraph,
            extending: false,
            confined: true
        )
    }

    open override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .paragraph,
            extending: true,
            confined: true
        )
    }

    open override func moveToBeginningOfDocument(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .document,
            extending: false,
            confined: false
        )
    }

    open override func moveToBeginningOfDocumentAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .document,
            extending: true,
            confined: false
        )
    }

    open override func moveToEndOfDocument(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .document,
            extending: false, 
            confined: false
        )
    }

    open override func moveToEndOfDocumentAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .document,
            extending: true,
            confined: false
        )
    }

    private func setTextSelections(
        direction: NSTextSelectionNavigation.Direction,
        destination: NSTextSelectionNavigation.Destination,
        extending: Bool,
        confined: Bool
    ) {
        guard isSelectable else { return }

        textLayoutManager.textSelections = textLayoutManager.textSelections.compactMap { textSelection in
            textLayoutManager.textSelectionNavigation.destinationSelection(
                for: textSelection,
                direction: direction,
                destination: destination,
                extending: extending,
                confined: confined
            )
        }

        updateTypingAttributes()
        needsScrollToSelection = true
        needsDisplay = true
    }

    internal func updateTextSelection(
        interactingAt point: CGPoint,
        inContainerAt location: NSTextLocation,
        anchors: [NSTextSelection] = [],
        extending: Bool,
        isDragging: Bool = false,
        visual: Bool = false
    ) {
        guard isSelectable else { return }

        var modifiers: NSTextSelectionNavigation.Modifier = []
        if extending {
            modifiers.insert(.extend)
        }
        if visual {
            modifiers.insert(.visual)
        }

        let selections = textLayoutManager.textSelectionNavigation.textSelections(
            interactingAt: point,
            inContainerAt: location,
            anchors: anchors,
            modifiers: modifiers,
            selecting: isDragging,
            bounds: textLayoutManager.usageBoundsForTextContainer
        )

        if !selections.isEmpty {
            textLayoutManager.textSelections = selections
        }

        updateTypingAttributes()
        updateSelectedRangeHighlight()
        layoutGutter()
        updateSelectedLineHighlight()
        needsDisplay = true
    }

}
