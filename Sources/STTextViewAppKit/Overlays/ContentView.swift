//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class ContentView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        // layer?.backgroundColor = NSColor.yellow.withAlphaComponent(0.2).cgColor
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        clipsToBounds = true
    }

    override var isFlipped: Bool {
#if os(macOS)
        true
#else
        false
#endif
    }
}
