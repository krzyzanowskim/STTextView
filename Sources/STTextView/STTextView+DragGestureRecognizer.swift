//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSGestureRecognizerDelegate {

    /// Gesture action for press and drag selected
    @objc func _dragSelectedTextGestureRecognizer(gestureRecognizer: NSGestureRecognizer) {
        let eventPoint = gestureRecognizer.location(in: self)
        let currentSelectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)

        guard !currentSelectionRanges.isEmpty else {
            return
        }

        // TODO: loop over all selected ranges
        guard interactionInSelectedRange(at: eventPoint),
              let selectionsAttributedString = textLayoutManager.textSelectionsAttributedString(),
              let textRange = currentSelectionRanges.first else {
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

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: NSGestureRecognizer) -> Bool {

        if gestureRecognizer == self.dragSelectedTextGestureRecognizer {
            return shouldRecognizeDragGesture(gestureRecognizer)
        }

        return true
    }

    private func shouldRecognizeDragGesture(_ gestureRecognizer: NSGestureRecognizer) -> Bool {
        let eventPoint = gestureRecognizer.location(in: self)
        return interactionInSelectedRange(at: eventPoint)
    }

    private func interactionInSelectedRange(at location: CGPoint) -> Bool {
        let currentSelectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
        if currentSelectionRanges.isEmpty {
            return false
        }

        return currentSelectionRanges.reduce(true) { partialResult, range in
            guard let interationLocation = textLayoutManager.location(interactingAt: location, inContainerAt: range.location) else {
                return partialResult
            }
            return partialResult && range.contains(interationLocation)
        }
    }

}
