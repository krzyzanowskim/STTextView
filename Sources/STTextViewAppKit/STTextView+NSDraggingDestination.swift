//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import UniformTypeIdentifiers

/// A set of methods that the destination object (or recipient) of a dragged image must implement.
///
/// NSView conforms to NSDraggingDestination
extension STTextView {

    open override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        super.concludeDragOperation(sender)
        cleanUpAfterDragOperation()
    }
    
    open override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    open override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let eventPoint = contentView.convert(sender.draggingLocation, from: nil)
        updateTextSelection(
            interactingAt: eventPoint,
            inContainerAt: textLayoutManager.documentRange.location,
            anchors: [],
            extending: false,
            isDragging: false,
            visual: false
        )
        return .copy
    }
    
    open override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        if isRichText && pasteboard.canReadItem(withDataConformingToTypes: [UTType.rtf.identifier]) {
            return readSelection(from: sender.draggingPasteboard, type: .rtf)
        } else if pasteboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]) {
            return readSelection(from: sender.draggingPasteboard, type: .string)
        }
        return false
    }
}
