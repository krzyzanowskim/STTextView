//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

final class STSelectionHighlightView: NSView {

    private static let emphasizedColor = NSColor.selectedTextBackgroundColor
    private static let unemphasizedColor = NSColor.unemphasizedSelectedTextBackgroundColor

    var backgroundColor: NSColor? {
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

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        self.backgroundColor = window?.isKeyWindow == true ? Self.emphasizedColor : Self.unemphasizedColor

        NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] notification in
            self?.backgroundColor = Self.emphasizedColor
        }

        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] notification in
            self?.backgroundColor = Self.unemphasizedColor
        }
    }
}
