import Foundation
import Cocoa

import STTextView

public struct DummyPlugin: STPlugin {

    public init() { }

    public func setUp(context: Context) {
        context.events.onWillChangeText(willChangeText)
        context.events.onDidChangeText(didChangeText)
        context.events.shouldChangeText(shouldChangeText)
        context.events.onContextMenu(contextMenu)
    }

    private func willChangeText(in affectedRange: NSTextRange) {
        // print("will change handler!")
    }

    private func didChangeText(in affectedRange: NSTextRange, replacementString: String?) {
        // print("did change handler!")
    }

    private func shouldChangeText(in textRange: NSTextRange, replacementString: String?) -> Bool {
        // if replacementString == "a" {
        //    return false
        // }
        return true
    }

    private func contextMenu(_ location: NSTextLocation, _ contentManager: NSTextContentManager) -> NSMenu {
        let menu = NSMenu(title: "Dummy Plugin")
        menu.autoenablesItems = false
        menu.addItem(withTitle: "Dummy Action", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Smart Action", action: nil, keyEquivalent: "")
        return menu
    }
}
