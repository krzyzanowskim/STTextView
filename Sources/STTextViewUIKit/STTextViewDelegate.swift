//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import UIKit

/// A set of optional methods that text view delegates can use to manage selection,
/// set text attributes and more.
public protocol STTextViewDelegate: AnyObject {
    /// Returns the undo manager for the specified text view.
    ///
    /// This method provides the flexibility to return a custom undo manager for the text view.
    /// Although STTextView implements undo and redo for changes to text,
    /// applications may need a custom undo manager to handle interactions between changes
    /// to text and changes to other items in the application.
    func undoManager(for textView: STTextView) -> UndoManager?

    /// Any keyDown or paste which changes the contents causes this
    func textViewWillChangeText(_ notification: Notification)

    /// Informs the delegate that the text object has changed its characters or formatting attributes.
    func textViewDidChangeText(_ notification: Notification)

    /// Sent when the selection changes in the text view.
    ///
    /// You can use the selectedRange property of the text view to get the new selection.
    func textViewDidChangeSelection(_ notification: Notification)

    /// Sent when a text view needs to determine if text in a specified range should be changed.
    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool

    /// Sent when a text view will change text.
    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String)

    /// Sent when a text view did change text.
    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String)

    // MARK: Clicking and Pasting

    /// Sent after the user clicks a link.
    /// - Parameters:
    ///   - textView: The text view sending the message.
    ///   - link: The link that was clicked; the value of link is either URL or String.
    ///   - location: The location where the click occurred.
    /// - Returns: true if the click was handled; otherwise, false to allow the next responder to handle it.
    func textView(_ textView: STTextView, clickedOnLink link: Any, at location: any NSTextLocation) -> Bool
}

// MARK: - Default implementation

public extension STTextViewDelegate {

    func undoManager(for textView: STTextView) -> UndoManager? {
        nil
    }

    func textViewWillChangeText(_ notification: Notification) {
        //
    }

    func textViewDidChangeText(_ notification: Notification) {
        //
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        //
    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        true
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {}

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {}

    func textView(_ textView: STTextView, clickedOnLink link: Any, at location: any NSTextLocation) -> Bool {
        false
    }

}
