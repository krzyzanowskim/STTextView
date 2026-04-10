//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

private let emphasizedColor = NSColor.selectedTextBackgroundColor
private let unemphasizedColor = NSColor.unemphasizedSelectedTextBackgroundColor

final class STSelectionHighlightView: NSView {

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
            self.updateBackgroundColor()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        updateBackgroundColor()

        NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
            self?.updateBackgroundColor()
        }

        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
            self?.updateBackgroundColor()
        }
    }

    private func updateBackgroundColor() {
        backgroundColor = shouldUseEmphasizedColor ? emphasizedColor : unemphasizedColor
    }

    private var shouldUseEmphasizedColor: Bool {
        guard let window, window.isKeyWindow else { return false }
        guard let textView = findParentTextView() else { return true }
        return textView.isFirstResponder
    }
}
