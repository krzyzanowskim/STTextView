//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    public override func mouseDown(with event: NSEvent) {
        
        if isSelectable, event.type == .leftMouseDown {
            let point = convert(event.locationInWindow, from: nil)
            updateTextSelection(
                interactingAt: point,
                inContainerAt: textLayoutManager.documentRange.location,
                anchors: event.modifierFlags.contains(.shift) ? textLayoutManager.textSelections : [],
                extending: event.modifierFlags.contains(.shift)
            )
        } else {
            super.mouseDown(with: event)
        }
    }

    public override func mouseDragged(with event: NSEvent) {
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
