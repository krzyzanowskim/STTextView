//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

@objc public protocol STTextViewDelegate: AnyObject {
    /// Any keyDown or paste which changes the contents causes this
    @objc optional func textWillChange(_ notification: Notification)
    /// Any keyDown or paste which changes the contents causes this
    @objc optional func textDidChange(_ notification: Notification)
    /// Sent when the selection changes in the text view.
    @objc optional func textViewDidChangeSelection(_ notification: Notification)
    /// Sent when a text view needs to determine if text in a specified range should be changed.
    @objc optional func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool
    /// Sent when a text view did change text.
    @objc optional func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String)
    ///
    @objc optional func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STTextView.LineAnnotation, textLineFragment: NSTextLineFragment) -> CALayer?
}
