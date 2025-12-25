//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class STSelectionHighlightView: NSView {

    var backgroundColor: NSColor? = .selectedTextBackgroundColor {
        didSet {
            layer?.backgroundColor = backgroundColor?.cgColor
        }
    }

    override var isFlipped: Bool {
        #if os(macOS)
            true
        #else
            false
        #endif
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        clipsToBounds = true
        layer?.backgroundColor = backgroundColor?.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            self.backgroundColor = self.backgroundColor
        }
    }
}
