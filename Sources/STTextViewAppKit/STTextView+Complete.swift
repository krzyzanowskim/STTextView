//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Supporting Autocomplete
    ///
    /// see NSStandardKeyBindingResponding
    open override func complete(_ sender: Any?) {
        if let completionWindowController, completionWindowController.isVisible {
            completionWindowController.close()
        } else {
            performCompletion()
        }
    }

    open override func cancelOperation(_ sender: Any?) {
        self.complete(sender)
    }

    @MainActor
    private func performCompletion() {
        guard let insertionPointLocation = textLayoutManager.insertionPointLocations.first,
              let textCharacterSegmentRect = textLayoutManager.textSegmentFrame(at: insertionPointLocation, type: .standard)
        else {
            self.completionWindowController?.close()
            return
        }

        // move left by arbitrary 14px
        let characterSegmentFrame = textCharacterSegmentRect.moved(dx: -14, dy: textCharacterSegmentRect.height)

        let completionItems = delegateProxy.textView(self, completionItemsAtLocation: insertionPointLocation) ?? []

        dispatchPrecondition(condition: .onQueue(.main))

        if completionItems.isEmpty {
            self.completionWindowController?.close()
        } else if let window = self.window {
            let completionWindowOrigin = window.convertPoint(toScreen: contentView.convert(characterSegmentFrame.origin, to: nil))
            completionWindowController?.showWindow(at: completionWindowOrigin, items: completionItems, parent: window)
            completionWindowController?.delegate = self
        }
    }
}

extension STTextView: STCompletionWindowDelegate {
    public func completionWindowController(_ windowController: STCompletionWindowController, complete item: any STCompletionItem, movement: NSTextMovement) {
        delegateProxy.textView(self, insertCompletionItem: item)
    }
}
