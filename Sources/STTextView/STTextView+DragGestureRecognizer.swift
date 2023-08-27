//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    /// Gesture action for press and drag selected
    @objc func _dragSelectedTextGestureRecognizer(gestureRecognizer: NSGestureRecognizer) {
        let currentSelectionRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)

        guard !currentSelectionRanges.isEmpty else {
            return
        }

        // TODO: loop over all selected ranges
        guard let selectionsAttributedString = textLayoutManager.textSelectionsAttributedString(),
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

}
