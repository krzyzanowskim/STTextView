//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class HighlightView: NSView {
    override var isFlipped: Bool {
#if os(macOS)
        true
#else
        false
#endif
    }
}
