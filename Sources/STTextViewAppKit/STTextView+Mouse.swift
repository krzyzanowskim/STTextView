//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView {

    override open func mouseDown(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        guard isSelectable, event.type == .leftMouseDown else {
            super.mouseDown(with: event)
            return
        }

        var handled = false
        let eventPoint = contentView.convert(event.locationInWindow, from: nil)
        let holdsShift = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.shift)
        let holdsControl = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.control)
        let holdsOption = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option)

        switch event.clickCount {
        case 1:
            if !handled, holdsShift, holdsControl {
                textLayoutManager.appendInsertionPointSelection(interactingAt: eventPoint)
                updateTypingAttributes()
                updateSelectedRangeHighlight()
                updateSelectedLineHighlight()
                layoutGutter()
                needsDisplay = true
                handled = true
            }

            if !handled, !holdsShift, !holdsOption, !holdsControl,
               let interactionLocation = textLayoutManager.caretLocation(interactingAt: eventPoint, inContainerAt: textLayoutManager.documentRange.location) {
                // Check for text attachment first
                // Note: This handles clicks on the text attachment character, not direct clicks on attachment views
                // Direct clicks on attachment views are handled by the attachment views themselves due to hitTest fix
                if let attachmentAttributeValue = textLayoutManager.textAttributedString(at: interactionLocation)?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment {
                    // First, select the attachment
                    selectAttachment(at: interactionLocation)

                    // Then call delegate methods
                    if delegateProxy.textView(self, shouldAllowInteractionWith: attachmentAttributeValue, at: interactionLocation) {
                        if !delegateProxy.textView(self, clickedOnAttachment: attachmentAttributeValue, at: interactionLocation) {
                            // Default attachment handling - could be extended for specific attachment types
                        }
                        handled = true
                    }
                }

                // Check for link if no attachment was handled
                if !handled, let linkAttributeValue = textLayoutManager.textAttributedString(at: interactionLocation)?.attribute(.link, at: 0, effectiveRange: nil) {
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
            // Double-tap to select is different than regular selection.
            // It select last word in the line or in the document.
            // https://github.com/krzyzanowskim/STTextView/discussions/93
            if let caretLocation = textLayoutManager.caretLocation(interactingAt: eventPoint, options: .allowOutside, inContainerAt: textLayoutManager.documentRange.location) {
                textLayoutManager.textSelections = [NSTextSelection(caretLocation, affinity: .downstream)]
            } else if let interactionRange = textLayoutManager.textSelectionNavigation.textSelections(interactingAt: eventPoint, inContainerAt: textLayoutManager.documentRange.location, anchors: [], modifiers: [], selecting: false, bounds: textLayoutManager.usageBoundsForTextContainer).first?.textRanges.last,
                      interactionRange.location >= textLayoutManager.documentRange.endLocation {
                // effective selection is end of the document
                var lastTextLayoutFragment: NSTextLayoutFragment? = nil
                textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.endLocation, options: .reverse) { textLayoutFragment in
                    lastTextLayoutFragment = textLayoutFragment
                    return false
                }

                if let lastTextLayoutFragment, !lastTextLayoutFragment.isExtraLineFragment {
                    var lastLocation: (any NSTextLocation)? = nil
                    textLayoutManager.enumerateCaretOffsetsInLineFragment(at: lastTextLayoutFragment.rangeInElement.location) { _, location, isLeading, _ in
                        if isLeading {
                            lastLocation = location
                        }
                    }

                    if let lastLocation {
                        textLayoutManager.textSelections = [NSTextSelection(lastLocation, affinity: .downstream)]
                    }
                }
            }

            selectWord(self)
            handled = true
        case 3:
            selectParagraph(self)
            handled = true
        default:
            handled = false
        }

        if !handled {
            // The default implementation simply passes this message to the next responder.
            super.mouseDown(with: event)
        }
    }

    override open func mouseUp(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        mouseDraggingSelectionAnchors = nil
        super.mouseUp(with: event)
    }

    override open func mouseDragged(with event: NSEvent) {
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

    override open func mouseMoved(with event: NSEvent) {
        guard (inputContext?.handleEvent(event) ?? false) == false else {
            return
        }

        super.mouseMoved(with: event)
    }

    override open func rightMouseDown(with event: NSEvent) {

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

    override open func menu(for event: NSEvent) -> NSMenu? {
        let proposedMenu = super.menu(for: event)?.copy() as? NSMenu

        // Disable context menu when adding an insertion point in mouseDown
        if proposedMenu != nil, event.type == .leftMouseDown, event.modifierFlags.intersection(.deviceIndependentFlagsMask).isSuperset(of: [.shift, .control]) {
            return nil
        }

        let point = contentView.convert(event.locationInWindow, from: nil)
        if let proposedMenu,
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

