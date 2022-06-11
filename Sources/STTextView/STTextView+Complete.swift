import Foundation
import Cocoa

extension STTextView {

    open override func complete(_ sender: Any?) {
        if completionWindowController.isVisible {
            completionWindowController.close()
        } else {
            performCompletion()
        }
    }

    open override func cancelOperation(_ sender: Any?) {
        self.complete(sender)
    }

    private func performCompletion() {
        guard let insertionPointLocation = textLayoutManager.insertionPointLocation,
              let textCharacterSegmentRect = textLayoutManager.textSelectionSegmentFrame(at: insertionPointLocation, type: .standard)
        else {
            self.completionWindowController.close()
            return
        }

        let characterSegmentFrame = textCharacterSegmentRect.applying(.init(translationX: 0, y: textCharacterSegmentRect.height))

        let completions = delegate?.textView(self, completionItemsAtLocation: insertionPointLocation) ?? []

        dispatchPrecondition(condition: .onQueue(.main))

        if completions.isEmpty {
            self.completionWindowController.close()
        } else if let window = self.window {
            let completionWindowOrigin = window.convertPoint(toScreen: convert(characterSegmentFrame.origin, to: nil))
            completionWindowController.showWindow(at: completionWindowOrigin, items: completions, parent: window)
            completionWindowController.delegate = self
        }
    }
}

extension STTextView: CompletionWindowDelegate {
    func completionWindowController(_ windowController: CompletionWindowController, complete item: Any, movement: NSTextMovement) {
        delegate?.textView(self, insertCompletionItem: item)
    }
}
