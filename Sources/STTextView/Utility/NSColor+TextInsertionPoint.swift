//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension NSColor {

    static var defaultTextInsertionPoint: NSColor? {
#if compiler(>=5.9)
        if #available(macOS 14, *) {
            return nil // default
        } else {
            return NSColor.textColor
        }
#elseif compiler(<5.9)
        return NSColor.textColor
#endif
    }
}
