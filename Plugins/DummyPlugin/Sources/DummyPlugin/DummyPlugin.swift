import Foundation
import AppKit
import OSLog
import STTextView

public struct DummyPlugin: STPlugin {

    public init() {

    }

    public func setUp(context: Context) {
        
    }
    
}

//public class CustomContext: STPluginContext {
//    public var textView: STTextView
//
//    init(textView: STTextView) {
//        self.textView = textView
//    }
//}

//    public func setUp(textView: STTextView) {
//        super.setUp(textView: textView)
//        register(eventHandler: self, of: textView)
//    }

//extension DummyPlugin: STPluginEventHandler {
//
//    public func textView(_ view: STTextView, menu: NSMenu, for event: NSEvent, at location: NSTextLocation) -> NSMenu? {
//        menu.addItem(.separator())
//        menu.addItem(withTitle: "Dummy Plugin Action", action: nil, keyEquivalent: "")
//        return menu
//    }
//
//    public func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
//
//    }
//
//    public func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
//
//    }
//
//    public func textViewWillChangeText(_ notification: Notification) {
//        //
//    }
//
//    public func textViewDidChangeText(_ notification: Notification) {
//        //
//    }
//
//    public func textViewDidChangeSelection(_ notification: Notification) {
//
//    }
//
//    public func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
//        true
//    }
//
//}
