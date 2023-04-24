//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

/// The methods that an object adopts to manage data and provide views for text view.
public protocol STTextViewDataSource: AnyObject {

    /// View for annotaion
    func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STLineAnnotation, textLineFragment: NSTextLineFragment) -> NSView?

    /// Annotations.
    ///
    /// Call `reloadData()` to notify STTextView about changes to annotations returned by this method.
    func textViewAnnotations(_ textView: STTextView) -> [STLineAnnotation]
}
