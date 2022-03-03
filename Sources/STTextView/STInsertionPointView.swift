//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

open class STInsertionPointView: NSView {
    private var timer: Timer?
    private let insertionPointWidth: CGFloat = 1

    public override var isFlipped: Bool {
        true
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true

        frame.size.width = insertionPointWidth
        frame.size.height -= 2
        frame.origin.y += 1
        layer?.backgroundColor = NSColor.textColor.withAlphaComponent(0.9).cgColor

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.isHidden.toggle()
        }
    }

    open override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview == nil {
            timer = nil
        }
    }
}
