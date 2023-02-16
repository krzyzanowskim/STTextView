//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    public func toggleRuler(_ sender: Any?) {
        isRulerVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    public var isRulerVisible: Bool {
        set {
            enclosingScrollView?.rulersVisible = newValue
        }
        get {
            enclosingScrollView?.rulersVisible ?? false
        }
    }

}
