import Foundation
import AppKit
import OSLog

import STTextView

internal let logger = Logger(subsystem: "best.swift.sttextview", category: "DummyPlugin")

public class DummyPlugin: STPlugin {

    public override func setUp(textView: STTextView) {
        super.setUp(textView: textView)

        logger.debug("set up dummy plugin")

        register(eventHandler: self, of: textView)
    }

    public override func tearDown() {
        super.tearDown()

        logger.debug("tear down dummy plugin")
    }

}

extension DummyPlugin: STPluginEventHandler {
    public func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {

    }

    public func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {

    }

    public func textView(_ view: STTextView, menu: NSMenu, for event: NSEvent, at location: NSTextLocation) -> NSMenu? {
        menu.addItem(.separator())
        menu.addItem(withTitle: "Dummy Plugin Action", action: nil, keyEquivalent: "")
        return menu
    }

    public func textViewWillChangeText(_ notification: Notification) {
        //
    }

    public func textViewDidChangeText(_ notification: Notification) {
        //
    }

    public func textViewDidChangeSelection(_ notification: Notification) {

    }

    public func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        true
    }

}
