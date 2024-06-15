//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension NSColor {
    static var defaultTextInsertionPoint: NSColor {
        if #available(macOS 14, *) {
            NSColor.textInsertionPointColor
        } else {
            NSColor.controlAccentColor
        }
    }
}
