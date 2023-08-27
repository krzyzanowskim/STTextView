//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

open class STInsertionPointView: NSView {
    private var timer: Timer?

    open internal(set) var insertionPointWidth: CGFloat? {
        didSet {
            updateGeometry()
        }
    }

    open internal(set) var insertionPointColor: NSColor = .defaultTextInsertionPoint {
        didSet {
            layer?.backgroundColor = insertionPointColor.cgColor
        }
    }

    public required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        updateGeometry()
    }


    public override var isFlipped: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    public func updateGeometry() {
        if let insertionPointWidth {
            frame.size.width = insertionPointWidth
        }
        layer?.backgroundColor = insertionPointColor.withAlphaComponent(0.9).cgColor
        layer?.cornerRadius = 1
    }

    open func blinkStart() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            self?.isHidden.toggle()
        }
    }

    open func blinkStop() {
        isHidden = false
        timer?.invalidate()
        timer = nil
    }
}
