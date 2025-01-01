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

        let rangeView = STTextLayoutRangeView(textLayoutManager: textLayoutManager, textRange: textRange)
        let draggingImage = rangeView.image()

        let draggingFrame = gestureRecognizer.view?.convert(rangeView.frame, from: contentView) ?? rangeView.frame

        let draggingItem = NSDraggingItem(pasteboardWriter: selectionsAttributedString)
        draggingItem.setDraggingFrame(draggingFrame, contents: draggingImage)

        draggingSession = beginDraggingSession(with: [draggingItem], event: NSApp.currentEvent!, source: self)
    }

}
