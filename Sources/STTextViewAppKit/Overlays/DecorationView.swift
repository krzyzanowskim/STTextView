//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

/// Custom rendering attributes
final class DecorationView: NSView {
    weak var textLayoutManager: NSTextLayoutManager?

    init(textLayoutManager: NSTextLayoutManager) {
        self.textLayoutManager = textLayoutManager
        super.init(frame: .zero)
        wantsLayer = true
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
//
//private extension NSUnderlineStyle {
//
//    /// Dots that NSTextView uses, that is not available otherwise as public API.
//    static var patternLargeDot: NSUnderlineStyle {
//        NSUnderlineStyle(rawValue: 0x11)
//    }
//}
