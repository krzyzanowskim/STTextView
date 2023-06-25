//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

/// A set of methods that the destination object (or recipient) of a dragged image must implement.
///
/// NSView conforms to NSDraggingDestination
extension STTextView {

    open override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        super.concludeDragOperation(sender)
        cleanUpAfterDragOperation()
    }

}
