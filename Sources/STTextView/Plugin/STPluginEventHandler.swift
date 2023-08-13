//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

//public protocol STPluginEventHandler: AnyObject {
//    func textViewWillChangeText(_ notification: Notification)
//    func textViewDidChangeText(_ notification: Notification)
//    func textViewDidChangeSelection(_ notification: Notification)
//    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool
//    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String)
//    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String)
//    func textView(_ view: STTextView, menu: NSMenu, for event: NSEvent, at location: NSTextLocation) -> NSMenu?
//}

//extension STPlugin {
//
//    struct EventHandler {
//
//        private var willChangeTextHandler: (() -> Void)?
//        private var didChangeTextHandler: (() -> Void)?
//
//        mutating func onWillChangeText(_ handler: @escaping () -> Void) {
//            willChangeTextHandler = handler
//        }
//
//        mutating func onDidChangeText(_ handler: @escaping () -> Void) {
//            didChangeTextHandler = handler
//        }
//
//    }
//}

//public protocol STPluginEventHandler2 {
//    func willChangeText()
//    func didChangeText()
//    func shouldChangeText(in range: NSTextRange, replacementString: String?) -> Bool
//}
//
//extension STPluginEventHandler2 {
//    func willChangeText() {
//        //
//    }
//
//    func didChangeText() {
//        //
//    }
//
//    func shouldChangeText(in range: NSTextRange, replacementString: String?) -> Bool {
//        true
//    }
//
//
//}
