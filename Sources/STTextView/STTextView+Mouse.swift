//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    open override func mouseDown(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        guard isSelectable, event.type == .leftMouseDown else {
            super.mouseDown(with: event)
            return
        }

        let handled: Bool

        switch event.clickCount {
        case 1:
            let eventPoint = convert(event.locationInWindow, from: nil)
//            let currentSelectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
//
//            lazy var interactionInSelectedRange: Bool = {
//                currentSelectionRanges.reduce(true) { partialResult, range in
//                    guard let interationLocation = textLayoutManager.location(interactingAt: eventPoint, inContainerAt: range.location) else {
//                        return partialResult
//                    }
//                    return partialResult && range.contains(interationLocation)
//                }
//            }()
//
//            if !currentSelectionRanges.isEmpty,
//               interactionInSelectedRange,
//               let selectionsAttributedString = textLayoutManager.textSelectionsAttributedString(),
//               let textRange = currentSelectionRanges.first // TODO: loop over ranges
//            {
//                // has selection, and tap on the selected area
//                // therefore start dragging session. dragging is interrupted
//                // by mouseup event, or any other mouse event
//                let rangeView = TextLayoutRangeView(textLayoutManager: textLayoutManager, textRange: textRange)
//                let imageRep = bitmapImageRepForCachingDisplay(in: rangeView.bounds)!
//                rangeView.cacheDisplay(in: rangeView.bounds, to: imageRep)
//
//                let draggingImage = NSImage(cgImage: imageRep.cgImage!, size: rangeView.bounds.size)
//
//                let draggingItem = NSDraggingItem(pasteboardWriter: selectionsAttributedString)
//                draggingItem.setDraggingFrame(rangeView.frame, contents: draggingImage)
//
//                beginDraggingSession(with: [draggingItem], event: event, source: self)
//            } else
            if event.modifierFlags.isSuperset(of: [.control, .shift]) {
                textLayoutManager.appendInsertionPointSelection(interactingAt: eventPoint)
                updateTypingAttributes()
                updateSelectionHighlights()
                needsDisplay = true
            } else {
                updateTextSelection(
                    interactingAt: eventPoint,
                    inContainerAt: textLayoutManager.documentRange.location,
                    anchors: event.modifierFlags.contains(.shift) ? textLayoutManager.textSelections : [],
                    extending: event.modifierFlags.contains(.shift),
                    isDragging: false,
                    visual: event.modifierFlags.contains(.option)
                )
            }
            handled = true
        case 2:
            selectWord(self)
            handled = true
        case 3:
            selectParagraph(self)
            handled = true
        default:
            handled = false
        }

        if !handled {
            super.mouseDown(with: event)
        }
    }

    open override func mouseUp(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        mouseDraggingSelectionAnchors = nil
        super.mouseUp(with: event)
    }

    open override func mouseDragged(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        guard isSelectable, (!event.deltaY.isZero || !event.deltaX.isZero) else {
            super.mouseDragged(with: event)
            return
        }

        let eventPoint = convert(event.locationInWindow, from: nil)

        if mouseDraggingSelectionAnchors == nil {
            mouseDraggingSelectionAnchors = textLayoutManager.textSelections
        }

        updateTextSelection(
            interactingAt: eventPoint,
            inContainerAt: mouseDraggingSelectionAnchors?.first?.textRanges.first?.location ?? textLayoutManager.documentRange.location,
            anchors: mouseDraggingSelectionAnchors!,
            extending: true,
            isDragging: true,
            visual: event.modifierFlags.contains(.option)
        )

        if autoscroll(with: event) {
            // TODO: periodic repeat this event, until don't
        }
    }

    open override func mouseMoved(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        super.mouseMoved(with: event)
    }

    open override func rightMouseDown(with event: NSEvent) {

        if menu(for: event) != nil {

            if textLayoutManager.textSelections.isEmpty {
                let point = convert(event.locationInWindow, from: nil)
                updateTextSelection(
                    interactingAt: point,
                    inContainerAt: textLayoutManager.documentRange.location,
                    anchors: event.modifierFlags.contains(.shift) ? textLayoutManager.textSelections : [],
                    extending: event.modifierFlags.contains(.shift)
                )

                selectWord(self)
            }
        }

        super.rightMouseDown(with: event)
    }

    open override func menu(for event: NSEvent) -> NSMenu? {
        let proposedMenu = super.menu(for: event)

        // Disable context menu when adding an insertion point in mouseDown
        if proposedMenu != nil, event.type == .leftMouseDown && event.modifierFlags.isSuperset(of: [.shift, .control]) {
            return nil
        }

        let point = convert(event.locationInWindow, from: nil)
        if let delegate = delegate,
           let proposedMenu = proposedMenu,
           let eventLocation = textLayoutManager.lineFragmentRange(for: point, inContainerAt: textLayoutManager.documentRange.location)?.location,
           let location = textLayoutManager.textSelectionNavigation.textSelections(interactingAt: point, inContainerAt: eventLocation, anchors: [], modifiers: [], selecting: false, bounds: textLayoutManager.usageBoundsForTextContainer).first?.textRanges.first?.location {
            return delegate.textView(self, menu: proposedMenu, for: event, at: location)
        }

        return proposedMenu
    }

}

