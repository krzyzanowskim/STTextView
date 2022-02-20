//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension STTextView {
    
    public override func selectAll(_ sender: Any?) {
        if isSelectable {
            textLayoutManager.textSelections = [
                NSTextSelection(range: textLayoutManager.documentRange, affinity: .downstream, granularity: .line)
            ]

            updateSelectionHighlights()

            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
            delegate?.textViewDidChangeSelection?(notification)
        }
    }

    public override func selectLine(_ sender: Any?) {
        assertionFailure()
    }

    public override func selectWord(_ sender: Any?) {
        assertionFailure()
    }

    public override func selectParagraph(_ sender: Any?) {
        assertionFailure()
    }

    public override func moveLeft(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .character,
            extending: false
        )
    }

    public override func moveLeftAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .character,
            extending: true
        )
    }

    public override func moveRight(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .character,
            extending: false
        )
    }

    public override func moveRightAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .character,
            extending: true
        )
    }

    public override func moveUp(_ sender: Any?) {
        updateTextSelection(
            direction: .up,
            destination: .character,
            extending: false
        )
    }

    public override func moveUpAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .up,
            destination: .character,
            extending: true
        )
    }

    public override func moveDown(_ sender: Any?) {
        updateTextSelection(
            direction: .down,
            destination: .character,
            extending: false
        )
    }

    public override func moveDownAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .down,
            destination: .character,
            extending: true
        )
    }

    public override func moveForward(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .character,
            extending: false
        )
    }

    public override func moveForwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .character,
            extending: true
        )
    }

    public override func moveBackward(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .character,
            extending: false
        )
    }

    public override func moveBackwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .character,
            extending: true
        )
    }

    public override func moveWordLeft(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .word,
            extending: false
        )
    }

    public override func moveWordLeftAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .word,
            extending: true
        )
    }

    public override func moveWordRight(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .word,
            extending: false
        )
    }

    public override func moveWordRightAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .word,
            extending: true
        )
    }

    public override func moveWordForward(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .word,
            extending: false
        )
    }

    public override func moveWordForwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .word,
            extending: true
        )
    }

    public override func moveWordBackward(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .word,
            extending: false
        )
    }

    public override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .word,
            extending: true
        )
    }

    public override func moveToBeginningOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .line,
            extending: false
        )
    }

    public override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .line,
            extending: true
        )
    }

    public override func moveToLeftEndOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .line,
            extending: false
        )
    }

    public override func moveToLeftEndOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .left,
            destination: .line,
            extending: true
        )
    }

    public override func moveToEndOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .line,
            extending: false
        )
    }

    public override func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .line,
            extending: true
        )
    }

    public override func moveToRightEndOfLine(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .line,
            extending: false
        )
    }

    public override func moveToRightEndOfLineAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .right,
            destination: .line,
            extending: true
        )
    }

    public override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .paragraph,
            extending: true
        )
    }

    public override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .paragraph,
            extending: true
        )
    }

    public override func moveToBeginningOfParagraph(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .paragraph,
            extending: false
        )
    }

    public override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .paragraph,
            extending: true
        )
    }

    public override func moveToEndOfParagraph(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .paragraph,
            extending: false
        )
    }

    public override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .paragraph,
            extending: true
        )
    }

    public override func moveToBeginningOfDocument(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .document,
            extending: false
        )
    }

    public override func moveToBeginningOfDocumentAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .backward,
            destination: .document,
            extending: true
        )
    }

    public override func moveToEndOfDocument(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .document,
            extending: false
        )
    }

    public override func moveToEndOfDocumentAndModifySelection(_ sender: Any?) {
        updateTextSelection(
            direction: .forward,
            destination: .document,
            extending: true
        )
    }

    private func updateTextSelection(direction: NSTextSelectionNavigation.Direction, destination: NSTextSelectionNavigation.Destination, extending: Bool, shouldScrollToVisible: Bool = true) {
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

        updateSelectionHighlights()
        needsDisplay = true

        if shouldScrollToVisible, let lastSelection = textLayoutManager.textSelections.last {
            scrollToSelection(lastSelection)
        }

        let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegate?.textViewDidChangeSelection?(notification)
    }

    func updateTextSelection(interactingAt point: CGPoint, inContainerAt location: NSTextLocation, anchors: [NSTextSelection] = [], extending: Bool, visual: Bool = false, shouldScrollToVisible: Bool = true) {
        guard isSelectable else { return }

        var modifiers: NSTextSelectionNavigation.Modifier = []
        if extending {
            modifiers.insert(.extend)
        }
        if visual {
            modifiers.insert(.visual)
        }
        
        textLayoutManager.textSelections = textLayoutManager.textSelectionNavigation.textSelections(interactingAt: point,
                                                   inContainerAt: location,
                                                   anchors: anchors,
                                                   modifiers: modifiers,
                                                   selecting: true,
                                                   bounds: .zero)

        updateSelectionHighlights()
        needsDisplay = true

        if shouldScrollToVisible, let lastSelection = textLayoutManager.textSelections.last {
            scrollToSelection(lastSelection)
        }

        let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegate?.textViewDidChangeSelection?(notification)
    }

    private func scrollToSelection(_ selection: NSTextSelection) {
        if let selectionTextRange = selection.textRanges.first {

            if selectionTextRange.isEmpty {
                if let textLayoutFragment = textLayoutManager.textLayoutFragment(for: selectionTextRange.location) {
                    scrollToVisible(textLayoutFragment.layoutFragmentFrame)
                }
            } else {
                switch selection.affinity {
                case .upstream:
                    if let textLayoutFragment = textLayoutManager.textLayoutFragment(for: selectionTextRange.location) {
                        scrollToVisible(textLayoutFragment.layoutFragmentFrame)
                    }
                case .downstream:
                    if let location = textLayoutManager.location(selectionTextRange.endLocation, offsetBy: -1),
                       let textLayoutFragment = textLayoutManager.textLayoutFragment(for: location)
                    {
                        self.scrollToVisible(textLayoutFragment.layoutFragmentFrame)
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}
