//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    open override func mouseDown(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        guard isSelectable, event.type == .leftMouseDown else {
            super.mouseDown(with: event)
            return
        }

        var handled: Bool = false

        switch event.clickCount {
        case 1:
            let eventPoint = contentView.convert(event.locationInWindow, from: nil)

            let holdsShift = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.shift)
            let holdsControl = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.control)
            let holdsOption = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option)

            if !handled, holdsShift && holdsControl {
                textLayoutManager.appendInsertionPointSelection(interactingAt: eventPoint)
                updateTypingAttributes()
                updateSelectedRangeHighlight()
                layoutGutter()
                updateSelectedLineHighlight()
                needsDisplay = true
                handled = true
            }

            if !handled, !holdsShift, !holdsOption, !holdsControl,
               let interactionLocation = textLayoutManager.location(interactingAt: eventPoint, inContainerAt: textLayoutManager.documentRange.location),
               let linkAttributeValue = textLayoutManager.textAttributedString(at: interactionLocation)?.attribute(.link, at: 0, effectiveRange: nil) {
                // The value of this attribute is an NSURL object (preferred) or an NSString object. The default value of this property is nil, indicating no link.
                let linkURL: URL? = switch linkAttributeValue {
                    case let value as URL:
                        value
                    case let value as String:
                        URL(string: value)
                    default:
                        nil
                    }

                if let linkURL {
                    if !self.delegateProxy.textView(self, clickedOnLink: linkAttributeValue, at: interactionLocation) {
                        if NSWorkspace.shared.urlForApplication(toOpen: linkURL) != nil {
                            NSWorkspace.shared.open(linkURL)
                        }
                    }
                    handled = true
                }
            }

            if !handled {
                updateTextSelection(
                    interactingAt: eventPoint,
                    inContainerAt: textLayoutManager.documentRange.location,
                    anchors: holdsShift ? textLayoutManager.textSelections : [],
                    extending: holdsShift,
                    isDragging: false,
                    visual: holdsOption
                )
                handled = true
            }
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

        let eventPoint = contentView.convert(event.locationInWindow, from: nil)

        if mouseDraggingSelectionAnchors == nil {
            mouseDraggingSelectionAnchors = textLayoutManager.textSelections
        }

        updateTextSelection(
            interactingAt: eventPoint,
            inContainerAt: mouseDraggingSelectionAnchors?.first?.textRanges.first?.location ?? textLayoutManager.documentRange.location,
            anchors: mouseDraggingSelectionAnchors!,
            extending: true,
            isDragging: true,
            visual: event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option)
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

            if textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty {
                let point = contentView.convert(event.locationInWindow, from: nil)
                updateTextSelection(
                    interactingAt: point,
                    inContainerAt: textLayoutManager.documentRange.location,
                    anchors: event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.shift) ? textLayoutManager.textSelections : [],
                    extending: event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.shift)
                )

                selectWord(self)
            }
        }

        super.rightMouseDown(with: event)
    }

    open override func menu(for event: NSEvent) -> NSMenu? {
        let proposedMenu = super.menu(for: event)?.copy() as? NSMenu

        // Disable context menu when adding an insertion point in mouseDown
        if proposedMenu != nil, event.type == .leftMouseDown && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isSuperset(of: [.shift, .control]) {
            return nil
        }

        let point = contentView.convert(event.locationInWindow, from: nil)
        if let proposedMenu = proposedMenu,
           let eventLocation = textLayoutManager.lineFragmentRange(for: point, inContainerAt: textLayoutManager.documentRange.location)?.location,
           let location = textLayoutManager.textSelectionNavigation.textSelections(interactingAt: point, inContainerAt: eventLocation, anchors: [], modifiers: [], selecting: false, bounds: textLayoutManager.usageBoundsForTextContainer).first?.textRanges.first?.location {

            // Insert spell checker menu
            do {
                var effectiveRange = NSRange()
                if let textCheckingMenu = textCheckingController.menu(at: NSRange(NSTextRange(location: location), in: textContentManager).location, clickedOnSelection: true, effectiveRange: &effectiveRange) {
                    let items = textCheckingMenu.items
                    for (idx, menuItem) in items.enumerated() {
                        proposedMenu.insertItem(menuItem.copy() as! NSMenuItem, at: idx)
                    }
                    proposedMenu.insertItem(.separator(), at: items.count)
                }
            }

            let effectiveMenu = delegateProxy.textView(self, menu: proposedMenu, for: event, at: location)
            effectiveMenu?.addItem(.separator())
            return effectiveMenu
        }

        return proposedMenu
    }

}

