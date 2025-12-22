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

        let rangeView = STTextRenderView(textLayoutManager: textLayoutManager, textRange: textRange)
        rangeView.clipsToContent = true
        let draggingImage = rangeView.image()

        // Get the actual position of the selection in the content view
        var selectionOrigin = CGPoint.zero
        textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: []) { _, textSegmentFrame, _, _ in
            selectionOrigin = textSegmentFrame.origin
            return false // stop after first segment to get the origin
        }

        let draggingFrameInContentView = CGRect(origin: selectionOrigin, size: rangeView.frame.size)
        let draggingFrame = gestureRecognizer.view?.convert(draggingFrameInContentView, from: contentView) ?? draggingFrameInContentView

        let draggingItem = NSDraggingItem(pasteboardWriter: selectionsAttributedString)
        draggingItem.setDraggingFrame(draggingFrame, contents: draggingImage)

        draggingSession = beginDraggingSession(with: [draggingItem], event: NSApp.currentEvent!, source: self)
    }

}
