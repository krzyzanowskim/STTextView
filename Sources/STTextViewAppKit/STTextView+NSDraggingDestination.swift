//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import UniformTypeIdentifiers

/// A set of methods that the destination object (or recipient) of a dragged image must implement.
///
/// NSView conforms to NSDraggingDestination
extension STTextView {

    override open func concludeDragOperation(_ sender: NSDraggingInfo?) {
        super.concludeDragOperation(sender)
        cleanUpAfterDragOperation()
    }

    override open func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSource == nil ? .copy : .move
    }

    override open func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let eventPoint = contentView.convert(sender.draggingLocation, from: nil)
        updateTextSelection(
            interactingAt: eventPoint,
            inContainerAt: textLayoutManager.documentRange.location,
            anchors: [],
            extending: false,
            isDragging: false,
            visual: false
        )
        return sender.draggingSource == nil ? .copy : .move
    }

    override open func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        if let originalDragSelections {
            performInternalDragOperation(textSelections: originalDragSelections)
            return true
        }

        let pasteboard = sender.draggingPasteboard
        if isRichText, pasteboard.canReadItem(withDataConformingToTypes: [UTType.rtf.identifier]) {
            return readSelection(from: sender.draggingPasteboard, type: .rtf)
        } else if pasteboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]) {
            return readSelection(from: sender.draggingPasteboard, type: .string)
        }
        return false
    }

    // Takes an array of selections, removes them from the text and inserts them at a new point
    private func performInternalDragOperation(textSelections: [NSTextRange]) {
        guard let insertionPoint = textLayoutManager.textSelections.flatMap(\.textRanges).first else { return }

        let sortedSelections = textSelections.sorted {
            NSRange($0, in: textContentManager).location > NSRange($1, in: textContentManager).location
        }

        let textToInsert = sortedSelections
            .compactMap { textLayoutManager.textAttributedString(in: $0) }
            .enumerated()
            .reduce(NSMutableAttributedString()) { result, item in
                if item.offset > 0 { result.append(NSAttributedString(string: "\n")) }
                result.append(item.element)
                return result
            }

        let insertionOffset = NSRange(insertionPoint.location, in: textContentManager).location
        let deletedBeforeInsertion = sortedSelections
            .map { NSRange($0, in: textContentManager) }
            .filter { $0.upperBound <= insertionOffset }
            .reduce(0) { $0 + $1.length }

        undoManager?.beginUndoGrouping()
        for selection in sortedSelections {
            replaceCharacters(in: NSRange(selection, in: textContentManager), with: "")
        }
        let insertLocation = insertionOffset - deletedBeforeInsertion
        insertText(textToInsert, replacementRange: NSRange(location: insertLocation, length: 0))
        setSelectedRange(NSRange(location: insertLocation + textToInsert.length, length: 0))
        undoManager?.endUndoGrouping()
    }

}
