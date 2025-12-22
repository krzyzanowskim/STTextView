//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Supporting Autocomplete
    ///
    /// see ``NSStandardKeyBindingResponding``
    @MainActor
    override open func complete(_ sender: Any?) {
        let didPerformCompletion = performSyncCompletion()
        if !didPerformCompletion {
            _completionTask?.cancel()
            _completionTask = Task(priority: .userInitiated) { [weak self] in
                guard let self, !Task.isCancelled else { return }
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
    @preconcurrency @MainActor
    @objc open func cancelComplete(_ sender: Any?) {
        _completionTask?.cancel()
        _completionWindowController?.close()
        _completionWindowController = nil
    }

    @MainActor
    override open func cancelOperation(_ sender: Any?) {
        if let completionWindowController, completionWindowController.isVisible {
            cancelComplete(sender)
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
            cancelComplete(self)
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
            cancelComplete(self)
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
    public func completionWindowControllerCancel(_ windowController: STCompletionWindowController) {
        cancelComplete(windowController)
    }

    public func completionWindowController(_ windowController: STCompletionWindowController, complete item: any STCompletionItem, movement: NSTextMovement) {
        delegateProxy.textView(self, insertCompletionItem: item)
    }
}
