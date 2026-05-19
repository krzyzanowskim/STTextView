//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {
    private struct CompletionRequestSnapshot {
        let insertionPointLocation: any NSTextLocation
        let textCharacterSegmentRect: CGRect
        let selectedRanges: [NSRange]
        let textChangeGeneration: Int
    }

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

        showCompletionWindow(at: textCharacterSegmentRect, items: completionItems)

        return true
    }

    @MainActor @discardableResult
    private func performAsyncCompletion() async -> Bool {
        guard !Task.isCancelled, let request = completionRequest() else {
            return false
        }

        guard let completionItems = await delegateProxy.textView(self, completionItemsAtLocation: request.insertionPointLocation) else {
            return false
        }

        if Task.isCancelled || !isValidCompletionRequest(request) {
            return false
        }

        if completionItems.isEmpty {
            cancelComplete(self)
            return false
        }

        showCompletionWindow(at: request.textCharacterSegmentRect, items: completionItems)

        return true
    }

    @MainActor
    private func completionRequest() -> CompletionRequestSnapshot? {
        guard let insertionPointLocation = textLayoutManager.insertionPointLocations.first,
              let textCharacterSegmentRect = textLayoutManager.textSegmentFrame(at: insertionPointLocation, type: .standard)
        else {
            return nil
        }

        return CompletionRequestSnapshot(
            insertionPointLocation: insertionPointLocation,
            textCharacterSegmentRect: textCharacterSegmentRect,
            selectedRanges: completionSelectedRanges(),
            textChangeGeneration: _completionTextChangeGeneration
        )
    }

    @MainActor
    private func isValidCompletionRequest(_ request: CompletionRequestSnapshot) -> Bool {
        request.textChangeGeneration == _completionTextChangeGeneration &&
        request.selectedRanges == completionSelectedRanges()
    }

    @MainActor
    private func completionSelectedRanges() -> [NSRange] {
        textLayoutManager.textSelections.flatMap(\.textRanges).map {
            NSRange($0, in: textContentManager)
        }
    }

    @MainActor
    private func showCompletionWindow(at textCharacterSegmentRect: CGRect, items completionItems: [any STCompletionItem]) {
        guard let window else { return }

        // move left by arbitrary 14px
        let characterSegmentFrame = textCharacterSegmentRect.moved(dx: -14, dy: textCharacterSegmentRect.height)
        let completionWindowOrigin = window.convertPoint(toScreen: contentView.convert(characterSegmentFrame.origin, to: nil))
        completionWindowController?.showWindow(at: completionWindowOrigin, items: completionItems, parent: window)
        completionWindowController?.delegate = self
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
