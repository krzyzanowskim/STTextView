//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

class STTextViewDelegateProxy: STTextViewDelegate {
    internal private(set) weak var textView: STTextView?
    internal private(set) weak var sourceDelegate: STTextViewDelegate?
    internal private(set) weak var eventHandler: STPluginEventHandler?

    init(textView: STTextView?, handler: STPluginEventHandler?) {
        self.textView = textView
        self.sourceDelegate = textView?.delegate
        self.eventHandler = handler
    }

    func undoManager(for textView: STTextView) -> UndoManager? {
        sourceDelegate?.undoManager(for: textView)
        // TODO: UndoManagerProxy
    }

    func textViewWillChangeText(_ notification: Notification) {
        sourceDelegate?.textViewWillChangeText(notification)
        eventHandler?.textViewWillChangeText(notification)
    }

    func textViewDidChangeText(_ notification: Notification) {
        sourceDelegate?.textViewDidChangeText(notification)
        eventHandler?.textViewDidChangeText(notification)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        sourceDelegate?.textViewDidChangeSelection(notification)
        eventHandler?.textViewDidChangeSelection(notification)
    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        var result = sourceDelegate?.textView(textView, shouldChangeTextIn: affectedCharRange, replacementString: replacementString) ?? true
        result = result && eventHandler?.textView(textView, shouldChangeTextIn: affectedCharRange, replacementString: replacementString) ?? true
        return result
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        sourceDelegate?.textView(textView, willChangeTextIn: affectedCharRange, replacementString: replacementString)
    }

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        sourceDelegate?.textView(textView, didChangeTextIn: affectedCharRange, replacementString: replacementString)
    }

    func textView(_ view: STTextView, menu: NSMenu, for event: NSEvent, at location: NSTextLocation) -> NSMenu? {
        var resultMenu: NSMenu? = sourceDelegate?.textView(view, menu: menu, for: event, at: location)

        if let proposedMenu = resultMenu {
            resultMenu = eventHandler?.textView(view, menu: proposedMenu, for: event, at: location) ?? proposedMenu
        }

        return resultMenu
    }

    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) -> [any STCompletionItem]? {
        sourceDelegate?.textView(textView, completionItemsAtLocation: location)
    }

    func textView(_ textView: STTextView, insertCompletionItem item: any STCompletionItem) {
        sourceDelegate?.textView(textView, insertCompletionItem: item)
    }

    func textViewCompletionViewController(_ textView: STTextView) -> any STCompletionViewControllerProtocol {
        sourceDelegate?.textViewCompletionViewController(textView) ?? STCompletionViewController()
    }
}
