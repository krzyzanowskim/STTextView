//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Supporting Autocomplete
    ///
    /// see ``NSStandardKeyBindingResponding``
    @MainActor
    open override func complete(_ sender: Any?) {
        let didPerformCompletion = performSyncCompletion()
        if !didPerformCompletion {
            _completionTask?.cancel()
            _completionTask = Task(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                if Task.isCancelled {
                    return
                }
                let sessionId = UUID().uuidString
                logger.debug("async completion: \(sessionId)")
                let result = await performAsyncCompletion()
                logger.debug("async completion result: \(result) \(sessionId), cancelled: \(Task.isCancelled)")
            }
        }
    }

    /// Close completion window
    ///
    /// see ``complete(_:)``
    @MainActor
    public func cancelComplete(_ sender: Any?) {
        completionWindowController?.close()
    }

    @MainActor
    open override func cancelOperation(_ sender: Any?) {
        if let completionWindowController, completionWindowController.isVisible {
            completionWindowController.close()
        } else {
            self.complete(sender)
        }
    }


    @MainActor @_unavailableFromAsync
    private func performSyncCompletion() -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let insertionPointLocation = textLayoutManager.insertionPointLocations.first,
              let textCharacterSegmentRect = textLayoutManager.textSegmentFrame(at: insertionPointLocation, type: .standard),
              let completionItems = delegateProxy.textView(self, completionItemsAtLocation: insertionPointLocation)
        else {
            return false
        }

        if completionItems.isEmpty {
            completionWindowController?.close()
            return false
        }

        if let window = self.window {
            // move left by arbitrary 14px
            let characterSegmentFrame = textCharacterSegmentRect.moved(dx: -14, dy: textCharacterSegmentRect.height)
            let completionWindowOrigin = window.convertPoint(toScreen: contentView.convert(characterSegmentFrame.origin, to: nil))
            completionWindowController?.showWindow(at: completionWindowOrigin, items: completionItems, parent: window)
            completionWindowController?.delegate = self
        }

        return true
    }

    @MainActor @discardableResult
    private func performAsyncCompletion() async -> Bool {
        guard !Task.isCancelled,
              let insertionPointLocation = textLayoutManager.insertionPointLocations.first,
              let textCharacterSegmentRect = textLayoutManager.textSegmentFrame(at: insertionPointLocation, type: .standard)
        else {
            return false
        }

        if Task.isCancelled {
            return false
        }

        guard let completionItems = await delegateProxy.textView(self, completionItemsAtLocation: insertionPointLocation) else {
            return false
        }


        if Task.isCancelled {
            return false
        }

        if completionItems.isEmpty {
            completionWindowController?.close()
            return false
        }

        if Task.isCancelled {
            return false
        }

        if let window = self.window {
            // move left by arbitrary 14px
            let characterSegmentFrame = textCharacterSegmentRect.moved(dx: -14, dy: textCharacterSegmentRect.height)
            let completionWindowOrigin = window.convertPoint(toScreen: contentView.convert(characterSegmentFrame.origin, to: nil))
            completionWindowController?.showWindow(at: completionWindowOrigin, items: completionItems, parent: window)
            completionWindowController?.delegate = self
        }

        return true
    }
}

extension STTextView: STCompletionWindowDelegate {
    public func completionWindowController(_ windowController: STCompletionWindowController, complete item: any STCompletionItem, movement: NSTextMovement) {
        delegateProxy.textView(self, insertCompletionItem: item)
    }
}
