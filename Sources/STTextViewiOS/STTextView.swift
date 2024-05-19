//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//

import UIKit
import STTextKitPlus

@objc open class STTextView: UIScrollView {
    // TODO: Let's goooo

    /// A Boolean value that controls whether the text view allows the user to edit text.
    // @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isEditable: Bool = true {
        didSet {
            if isEditable == true {
                isSelectable = true
            }
        }
    }

    /// A Boolean value that controls whether the text views allows the user to select text.
    // @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isSelectable: Bool = true {
        didSet {
            if isSelectable == false {
                isEditable = false
            }
        }
    }
}
