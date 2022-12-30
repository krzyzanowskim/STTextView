//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {
    
    open override func selectAll(_ sender: Any?) {
        if isSelectable {
            textLayoutManager.textSelections = [
                NSTextSelection(range: textLayoutManager.documentRange, affinity: .downstream, granularity: .line)
            ]

            updateSelectionHighlights()
        }
    }

    open override func selectLine(_ sender: Any?) {
        guard let startSelection = textLayoutManager.textSelections.first else {
            return
        }

        textLayoutManager.textSelections = [
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .line,
                enclosing: startSelection
            )
        ]

        needScrollToSelection = true
        needsDisplay = true
    }

    open override func selectWord(_ sender: Any?) {
        guard let startSelection = textLayoutManager.textSelections.first else {
            return
        }

        textLayoutManager.textSelections = [
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .word,
                enclosing: startSelection
            )
        ]

        needScrollToSelection = true
        needsDisplay = true
    }

    open override func selectParagraph(_ sender: Any?) {
        guard let startSelection = textLayoutManager.textSelections.first else {
            return
        }

        textLayoutManager.textSelections = [
            textLayoutManager.textSelectionNavigation.textSelection(
                for: .paragraph,
                enclosing: startSelection
            )
        ]

        needScrollToSelection = true
        needsDisplay = true

    }

    open override func moveLeft(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .character,
            extending: false
        )
    }

    open override func moveLeftAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .character,
            extending: true
        )
    }

    open override func moveRight(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .character,
            extending: false
        )
    }

    open override func moveRightAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .character,
            extending: true
        )
    }

    open override func moveUp(_ sender: Any?) {
        updateTextSelection(
            direction: .up,
            destination: .character,
            extending: false
        )
    }

    open override func moveUpAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .up,
            destination: .character,
            extending: true
        )
    }

    open override func moveDown(_ sender: Any?) {
        updateTextSelection(
            direction: .down,
            destination: .character,
            extending: false
        )
    }

    open override func moveDownAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .down,
            destination: .character,
            extending: true
        )
    }

    open override func moveForward(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .character,
            extending: false
        )
    }

    open override func moveForwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .character,
            extending: true
        )
    }

    open override func moveBackward(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .character,
            extending: false
        )
    }

    open override func moveBackwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .character,
            extending: true
        )
    }

    open override func moveWordLeft(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .word,
            extending: false
        )
    }

    open override func moveWordLeftAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .word,
            extending: true
        )
    }

    open override func moveWordRight(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .word,
            extending: false
        )
    }

    open override func moveWordRightAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .word,
            extending: true
        )
    }

    open override func moveWordForward(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .word,
            extending: false
        )
    }

    open override func moveWordForwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .word,
            extending: true
        )
    }

    open override func moveWordBackward(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .word,
            extending: false
        )
    }

    open override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .word,
            extending: true
        )
    }

    open override func moveToBeginningOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .line,
            extending: false
        )
    }

    open override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .line,
            extending: true
        )
    }

    open override func moveToLeftEndOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .line,
            extending: false
        )
    }

    open override func moveToLeftEndOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .line,
            extending: true
        )
    }

    open override func moveToEndOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .line,
            extending: false
        )
    }

    open override func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .line,
            extending: true
        )
    }

    open override func moveToRightEndOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .line,
            extending: false
        )
    }

    open override func moveToRightEndOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .line,
            extending: true
        )
    }

    open override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .paragraph,
            extending: true
        )
    }

    open override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .paragraph,
            extending: true
        )
    }

    open override func moveToBeginningOfParagraph(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .paragraph,
            extending: false
        )
    }

    open override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .paragraph,
            extending: true
        )
    }

    open override func moveToEndOfParagraph(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .paragraph,
            extending: false
        )
    }

    open override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .paragraph,
            extending: true
        )
    }

    open override func moveToBeginningOfDocument(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .document,
            extending: false
        )
    }

    open override func moveToBeginningOfDocumentAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .document,
            extending: true
        )
    }

    open override func moveToEndOfDocument(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .document,
            extending: false
        )
    }

    open override func moveToEndOfDocumentAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .document,
            extending: true
        )
    }

    private func updateTextSelection(direction: NSTextSelectionNavigation.Direction, destination: NSTextSelectionNavigation.Destination, extending: Bool) {
        guard isSelectable else { return }

        textLayoutManager.textSelections = textLayoutManager.textSelections.compactMap { textSelection in
            textLayoutManager.textSelectionNavigation.destinationSelection(
                for: textSelection,
                direction: direction,
                destination: destination,
                extending: extending,
                confined: false
            )
        }

        needScrollToSelection = true
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

        // FB11898356
        // Something if wrong with textSelectionsInteractingAtPoint
        //
        // When drag mouse down it move text range to the previous line
        // that is unexpected. This happens only when the anchor location
        // is at the beginning of the line/paragraph
        //
        // Mouse position: (8.140625, 82.99609375)
        // [NSTextSelection:<0x60000153fb10> granularity=character, affinity=upstream, transient, anchor position offset=5.000000, anchor location 512, textRanges=(
        // "512...1106"
        // )]
        //
        // Mouse position: (8.484375, 83.20703125)
        // [NSTextSelection:<0x60000152f570> granularity=character, affinity=upstream, transient, anchor position offset=5.000000, anchor location 512, textRanges=(
        // "511...1106"
        // )]
        //
        let selections = textLayoutManager.textSelectionNavigation.textSelections(
            interactingAt: point,
            inContainerAt: location,
            anchors: anchors,
            modifiers: modifiers,
            selecting: isDragging,
            bounds: bounds
        )

        if !selections.isEmpty {
            textLayoutManager.textSelections = selections
        }

        updateSelectionHighlights()
        needsDisplay = true
    }

}
