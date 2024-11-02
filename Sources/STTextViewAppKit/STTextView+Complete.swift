//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Supporting Autocomplete
    ///
    /// see NSStandardKeyBindingResponding
    @MainActor
    open override func complete(_ sender: Any?) {
        if let completionWindowController, completionWindowController.isVisible {
            completionWindowController.close()
        } else {
            performCompletion()
        }
    }

    @MainActor
    open override func cancelOperation(_ sender: Any?) {
        self.complete(sender)
    }

    @MainActor
    private func performCompletion() {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let insertionPointLocation = textLayoutManager.insertionPointLocations.first,
              let textCharacterSegmentRect = textLayoutManager.textSegmentFrame(at: insertionPointLocation, type: .standard),
              let completionItems = delegateProxy.textView(self, completionItemsAtLocation: insertionPointLocation),
              completionItems.isEmpty == false
        else {
            if let completionWindowController, completionWindowController.isVisible {
                self.completionWindowController?.close()
            }
            return
        }

        if let window = self.window {
            // move left by arbitrary 14px
            let characterSegmentFrame = textCharacterSegmentRect.moved(dx: -14, dy: textCharacterSegmentRect.height)
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
