//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

class STTextViewDelegateProxy: STTextViewDelegate {
    weak var source: STTextViewDelegate?

    init(source: STTextViewDelegate?) {
        self.source = source
    }

    func undoManager(for textView: STTextView) -> UndoManager? {
        source?.undoManager(for: textView)
    }

    func textViewWillChangeText(_ notification: Notification) {
        source?.textViewWillChangeText(notification)
    }

    func textViewDidChangeText(_ notification: Notification) {
        source?.textViewDidChangeText(notification)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        source?.textViewDidChangeSelection(notification)
    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        var result = source?.textView(textView, shouldChangeTextIn: affectedCharRange, replacementString: replacementString) ?? true
        result = result && textView.plugins.events.reduce(result) { partialResult, events in
            partialResult && events.shouldChangeTextHandler?(affectedCharRange, replacementString) ?? true
        }
        return result
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        source?.textView(textView, willChangeTextIn: affectedCharRange, replacementString: replacementString)

        for events in textView.plugins.events {
            events.willChangeTextHandler?(affectedCharRange)
        }
    }

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        source?.textView(textView, didChangeTextIn: affectedCharRange, replacementString: replacementString)

        for events in textView.plugins.events {
            events.didChangeTextHandler?(affectedCharRange, replacementString)
        }

    }

    func textView(_ textView: STTextView, menu: NSMenu, for event: NSEvent, at location: NSTextLocation) -> NSMenu? {
        guard let textContentManager = textView.textLayoutManager.textContentManager else {
            return nil
        }

        let effectiveMenu = source?.textView(textView, menu: menu, for: event, at: location)

        // Append plugins menus
        let pluginMenus = textView.plugins.events.compactMap { events in
            events.onContextMenuHandler?(location, textContentManager)
        }

        if let effectiveMenu, !pluginMenus.isEmpty {
            effectiveMenu.addItem(.separator())

            for pluginMenu in pluginMenus {
                if pluginMenu.items.count == 1, let firstItem = pluginMenu.items.first?.copy() as? NSMenuItem {
                    effectiveMenu.addItem(firstItem)
                } else if pluginMenu.items.count > 1 {
                    let menuItem = effectiveMenu.addItem(withTitle: pluginMenu.title, action: nil, keyEquivalent: "")
                    menuItem.submenu = pluginMenu
                }
            }
        }

        return effectiveMenu
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

    func textViewInsertionPointView(_ textView: STTextView, frame: CGRect) -> (STInsertionPointIndicatorProtocol)? {
        source?.textViewInsertionPointView(textView, frame: frame)
    }

    func textView(_ textView: STTextView, clickedOnLink link: Any, at location: any NSTextLocation) -> Bool {
        source?.textView(textView, clickedOnLink: link, at: location) ?? false
    }

}
