//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

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

        // ^Space -> complete:
        if event.modifierFlags.contains(.control) && event.charactersIgnoringModifiers == " " {
            doCommand(by: #selector(NSStandardKeyBindingResponding.complete(_:)))
            return
        }

        if inputContext?.handleEvent(event) == false {
            interpretKeyEvents([event])
        }
    }
}
