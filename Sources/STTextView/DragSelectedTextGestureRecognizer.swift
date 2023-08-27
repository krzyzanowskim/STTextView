//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class DragSelectedTextGestureRecognizer: NSPressGestureRecognizer {

    override func mouseDown(with event: NSEvent) {
        guard let textView = self.view as? STTextView else {
            return
        }

        if isEnabled {
            let eventPoint = textView.convert(event.locationInWindow, from: nil)
            if !interactionInSelectedRange(at: eventPoint) {
                self.state = .failed
            }
        }

        super.mouseDown(with: event)
    }

    private func interactionInSelectedRange(at location: CGPoint) -> Bool {
        guard let textView = self.view as? STTextView else {
            return false
        }

        let currentSelectionRanges = textView.textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
        if currentSelectionRanges.isEmpty {
            return false
        }

        return currentSelectionRanges.reduce(true) { partialResult, range in
            guard let interationLocation = textView.textLayoutManager.location(interactingAt: location, inContainerAt: range.location) else {
                return partialResult
            }
            return partialResult && range.contains(interationLocation)
        }
    }
}
