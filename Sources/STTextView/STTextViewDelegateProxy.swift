//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

class STTextViewDelegateProxy: STTextViewDelegate {
    weak var source: STTextViewDelegate?

    init(source: STTextViewDelegate) {
        self.source = source
    }

    func undoManager(for textView: STTextView) -> UndoManager? {
        source?.undoManager(for: textView)
    }

    func textViewWillChangeText(_ notification: Notification) {
        guard let textView = notification.object as? STTextView else { return }
        source?.textViewWillChangeText(notification)

        for events in textView.plugins.events {
            events.willChangeTextHandler?()
        }
    }

    func textViewDidChangeText(_ notification: Notification) {
        guard let textView = notification.object as? STTextView else { return }

        source?.textViewDidChangeText(notification)

        for events in textView.plugins.events {
            events.didChangeTextHandler?()
        }
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        source?.textViewDidChangeSelection(notification)
    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        var result = source?.textView(textView, shouldChangeTextIn: affectedCharRange, replacementString: replacementString) ?? true
        result = result && textView.plugins.events.reduce(result) { partialResult, events in
            return partialResult && events.shouldChangeText?(affectedCharRange, replacementString) ?? true
        }
        return result
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        source?.textView(textView, willChangeTextIn: affectedCharRange, replacementString: replacementString)
    }

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        source?.textView(textView, didChangeTextIn: affectedCharRange, replacementString: replacementString)
    }

    func textView(_ view: STTextView, menu: NSMenu, for event: NSEvent, at location: NSTextLocation) -> NSMenu? {
        var resultMenu: NSMenu? = source?.textView(view, menu: menu, for: event, at: location)

        if let proposedMenu = resultMenu {
//            for events in textView.plugins.compactMap({ $0.events }) {
//                events.didChangeTextHandler?()
//            }

//            resultMenu = eventHandler?.textView(view, menu: proposedMenu, for: event, at: location) ?? proposedMenu
        }

        return resultMenu
    }

    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) -> [any STCompletionItem]? {
        source?.textView(textView, completionItemsAtLocation: location)
    }

    func textView(_ textView: STTextView, insertCompletionItem item: any STCompletionItem) {
        source?.textView(textView, insertCompletionItem: item)
    }

    func textViewCompletionViewController(_ textView: STTextView) -> any STCompletionViewControllerProtocol {
        source?.textViewCompletionViewController(textView) ?? STCompletionViewController()
    }
}

private extension Array<(plugin: STPlugin, events: STPluginEvents?)> {
    var events: [STPluginEvents] {
        compactMap({ $0.events })
    }
}
