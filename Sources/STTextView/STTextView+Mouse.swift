//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    open override func mouseDown(with event: NSEvent) {
        guard isSelectable, event.type == .leftMouseDown else {
            super.mouseDown(with: event)
            return
        }

        var handled = false

        if event.modifierFlags.isEmpty {
            if event.clickCount == 1 {
                let point = convert(event.locationInWindow, from: nil)
                updateTextSelection(
                    interactingAt: point,
                    inContainerAt: textLayoutManager.documentRange.location,
                    anchors: event.modifierFlags.contains(.shift) ? textLayoutManager.textSelections : [],
                    extending: event.modifierFlags.contains(.shift)
                )
                handled = true
            } else if event.clickCount == 2 {
                selectWord(self)
                handled = true
            } else if event.clickCount == 3 {
                selectLine(self)
                handled = true
            }
        }

        if !handled {
            super.mouseDown(with: event)
        }
    }

    open override func mouseDragged(with event: NSEvent) {
        if isSelectable, event.type == .leftMouseDragged, (!event.deltaY.isZero || !event.deltaX.isZero) {
            let point = convert(event.locationInWindow, from: nil)
            updateTextSelection(
                interactingAt: point,
                inContainerAt: textLayoutManager.documentRange.location,
                anchors: textLayoutManager.textSelections,
                extending: true,
                visual: event.modifierFlags.contains(.option)
            )

            if autoscroll(with: event) {
                // TODO: periodic repeat this event, until don't
            }
        } else {
            super.mouseDragged(with: event)
        }
    }
}
