//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

@objc public protocol STTextViewDelegate: AnyObject {
    /// Any keyDown or paste which changes the contents causes this
    @objc optional func textDidChange(_ notification: Notification)
    /// Sent when the selection changes in the text view.
    @objc optional func textViewDidChangeSelection(_ notification: Notification)
    /// Sent when a text view needs to determine if text in a specified range should be changed.
    @objc optional func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool
}
