//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView {

    func setSelectedTextRange(_ textRange: NSTextRange, updateLayout: Bool) {
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

    func setSelectedRange(_ range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            logger.warning("Invalid range \(range) \(#function)")
            return
        }
        setSelectedTextRange(textRange, updateLayout: true)
    }

    override open func selectAll(_ sender: Any?) {

        guard isSelectable else {
            return
        }

        textLayoutManager.textSelections = [
            NSTextSelection(range: textLayoutManager.documentRange, affinity: .downstream, granularity: .character)
        ]

        updateTypingAttributes()
        updateSelectedRangeHighlight()
        updateSelectedLineHighlight()
        layoutGutter()
    }

    override open func selectLine(_ sender: Any?) {
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

    override open func selectWord(_ sender: Any?) {
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

    override open func selectParagraph(_ sender: Any?) {
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

    override open func moveLeft(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    override open func moveLeftAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    override open func moveRight(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    override open func moveRightAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    override open func moveUp(_ sender: Any?) {
        setTextSelections(
            direction: .up,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    override open func moveUpAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .up,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    override open func moveDown(_ sender: Any?) {
        setTextSelections(
            direction: .down,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    override open func moveDownAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .down,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    override open func moveForward(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    override open func moveForwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    override open func moveBackward(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .character,
            extending: false,
            confined: false
        )
    }

    override open func moveBackwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .character,
            extending: true,
            confined: false
        )
    }

    override open func moveWordLeft(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    override open func moveWordLeftAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    override open func moveWordRight(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    override open func moveWordRightAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    override open func moveWordForward(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    override open func moveWordForwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    override open func moveWordBackward(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .word,
            extending: false,
            confined: false
        )
    }

    override open func moveWordBackwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .word,
            extending: true,
            confined: false
        )
    }

    override open func moveToBeginningOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    override open func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    override open func moveToLeftEndOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    override open func moveToLeftEndOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .left,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    override open func moveToEndOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    override open func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    override open func moveToRightEndOfLine(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .line,
            extending: false,
            confined: true
        )
    }

    override open func moveToRightEndOfLineAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .right,
            destination: .line,
            extending: true,
            confined: true
        )
    }

    override open func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .paragraph,
            extending: true,
            confined: false
        )
    }

    override open func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .paragraph,
            extending: true,
            confined: false
        )
    }

    override open func moveToBeginningOfParagraph(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .paragraph,
            extending: false,
            confined: true
        )
    }

    override open func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .paragraph,
            extending: true,
            confined: true
        )
    }

    override open func moveToEndOfParagraph(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .paragraph,
            extending: false,
            confined: true
        )
    }

    override open func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .paragraph,
            extending: true,
            confined: true
        )
    }

    override open func moveToBeginningOfDocument(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .document,
            extending: false,
            confined: false
        )
    }

    override open func moveToBeginningOfDocumentAndModifySelection(_ sender: Any?) {
        setTextSelections(
            direction: .backward,
            destination: .document,
            extending: true,
            confined: false
        )
    }

    override open func moveToEndOfDocument(_ sender: Any?) {
        setTextSelections(
            direction: .forward,
            destination: .document,
            extending: false,
            confined: false
        )
    }

    override open func moveToEndOfDocumentAndModifySelection(_ sender: Any?) {
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

    func updateTextSelection(
        interactingAt point: CGPoint,
        inContainerAt location: NSTextLocation,
        anchors: [NSTextSelection] = [],
        extending: Bool,
        isDragging: Bool = false,
        visual: Bool = false
    ) {
        guard isSelectable else { return }

        // For simple clicks (not extending, not dragging), use caretLocationWithAffinity
        // which correctly positions the caret at end-of-wrapped-lines with upstream affinity.
        // For extend/drag operations, use Apple's textSelections.
        if !extending && !isDragging && anchors.isEmpty {
            if let (caretLoc, affinity) = textLayoutManager.caretLocationWithAffinity(interactingAt: point, inContainerAt: location) {
                textLayoutManager.textSelections = [NSTextSelection(caretLoc, affinity: affinity)]
                updateTypingAttributes()
                updateSelectedRangeHighlight()
                updateSelectedLineHighlight()
                layoutGutter()
                needsDisplay = true
                return
            }
        }

        var modifiers: NSTextSelectionNavigation.Modifier = []
        if extending {
            modifiers.insert(.extend)
        }
        if visual {
            modifiers.insert(.visual)
        }

        let newSelections = textLayoutManager.textSelectionNavigation.textSelections(
            interactingAt: point,
            inContainerAt: location,
            anchors: anchors,
            modifiers: modifiers,
            selecting: isDragging,
            bounds: textLayoutManager.usageBoundsForTextContainer
        )

        if !newSelections.isEmpty {
            textLayoutManager.textSelections = newSelections
        }

        updateTypingAttributes()
        updateSelectedRangeHighlight()
        updateSelectedLineHighlight()
        layoutGutter()
        needsDisplay = true
    }

}
