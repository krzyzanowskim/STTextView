//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {
    open override func keyDown(with event: NSEvent) {
        
        guard isEditable else {
            super.keyDown(with: event)
            return
        }

        processingKeyEvent = true
        defer {
            processingKeyEvent = false
        }

        NSCursor.setHiddenUntilMouseMoves(true)

        if inputContext?.handleEvent(event) == false {
            interpretKeyEvents([event])
        }
    }

    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isEditable else {
            return super.performKeyEquivalent(with: event)
        }

        processingKeyEvent = true
        defer {
            processingKeyEvent = false
        }

        // ^Space -> complete:
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .control && event.charactersIgnoringModifiers == " " {
            doCommand(by: #selector(NSStandardKeyBindingResponding.complete(_:)))
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}
