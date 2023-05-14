//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {
    open override func keyDown(with event: NSEvent) {
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

        interpretKeyEvents([event])
    }
}
