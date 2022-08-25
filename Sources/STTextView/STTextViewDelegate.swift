//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

public protocol STTextViewDelegate: AnyObject {
    /// Any keyDown or paste which changes the contents causes this
    func textWillChange(_ notification: Notification)
    /// Any keyDown or paste which changes the contents causes this
    func textDidChange(_ notification: Notification)
    /// Sent when the selection changes in the text view.
    func textViewDidChangeSelection(_ notification: Notification)
    /// Sent when a text view needs to determine if text in a specified range should be changed.
    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool
    /// Sent when a text view will change text.
    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String)
    /// Sent when a text view did change text.
    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String)
    ///
    func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STLineAnnotation, textLineFragment: NSTextLineFragment) -> NSView?

    /// Completion items
    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) -> [Any]?

    func textView(_ textView: STTextView, insertCompletionItem item: Any)

    /// Sent when the caret is moved
    func textView(_ textView: STTextView, didMoveCaretTo row: Int, column: Int)

    // Due to Swift 5.6 generics limitation it can't return STCompletionViewControllerProtocol
    func textViewCompletionViewController(_ textView: STTextView) -> STAnyCompletionViewController?
}

public extension STTextViewDelegate {

    func textWillChange(_ notification: Notification) {
        //
    }

    func textDidChange(_ notification: Notification) {
        //
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        //
    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        true
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {

    }

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {

    }

    func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STLineAnnotation, textLineFragment: NSTextLineFragment) -> NSView? {
        nil
    }

    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) -> [Any]? {
        nil
    }

    func textView(_ textView: STTextView, insertCompletionItem item: Any) {
        
    }

    func textView(_ textView: STTextView, didMoveCaretTo row: Int, column: Int) {

    }
    
    func textViewCompletionViewController(_ textView: STTextView) -> STAnyCompletionViewController? {
        nil
    }
}
