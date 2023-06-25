//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    func dragSelectedTextGestureRecognizer() -> NSGestureRecognizer {
        let recognizer = NSPressGestureRecognizer(target: self, action: #selector(_dragSelectedTextGestureRecognizer(gestureRecognizer:)))
        recognizer.minimumPressDuration = NSEvent.doubleClickInterval / 3
        recognizer.delaysPrimaryMouseButtonEvents = true
        recognizer.isEnabled = isSelectable
        return recognizer
    }

    /// Gesture action for press and drag selected
    @objc private func _dragSelectedTextGestureRecognizer(gestureRecognizer: NSGestureRecognizer) {
        guard gestureRecognizer.state == .began else {
            return
        }

        let eventPoint = gestureRecognizer.location(in: self)
        let currentSelectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)

        guard !currentSelectionRanges.isEmpty else {
            return
        }

        lazy var interactionInSelectedRange: Bool = {
            currentSelectionRanges.reduce(true) { partialResult, range in
                guard let interationLocation = textLayoutManager.location(interactingAt: eventPoint, inContainerAt: range.location) else {
                    return partialResult
                }
                return partialResult && range.contains(interationLocation)
            }
        }()

        // TODO: loop over all selected ranges
        guard interactionInSelectedRange, let selectionsAttributedString = textLayoutManager.textSelectionsAttributedString(), let textRange = currentSelectionRanges.first else {
            return
        }

        let rangeView = TextLayoutRangeView(textLayoutManager: textLayoutManager, textRange: textRange)
        let imageRep = bitmapImageRepForCachingDisplay(in: rangeView.bounds)!
        rangeView.cacheDisplay(in: rangeView.bounds, to: imageRep)

        let draggingImage = NSImage(cgImage: imageRep.cgImage!, size: rangeView.bounds.size)

        let draggingItem = NSDraggingItem(pasteboardWriter: selectionsAttributedString)
        draggingItem.setDraggingFrame(rangeView.frame, contents: draggingImage)

        draggingSession = beginDraggingSession(with: [draggingItem], event: NSApp.currentEvent!, source: self)
    }
}
