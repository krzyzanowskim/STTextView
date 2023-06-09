//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

open class STInsertionPointView: NSView {
    private var timer: Timer?

    open internal(set) var insertionPointWidth: CGFloat = 1 {
        didSet {
            frame.size.width = insertionPointWidth
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
        frame = frame.insetBy(dx: 0, dy: 1).pixelAligned
        frame.size.width = insertionPointWidth
        layer?.backgroundColor = insertionPointColor.cgColor
    }

    open func blinkStart() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.isHidden.toggle()
        }
    }

    open func blinkStop() {
        isHidden = false
        timer = nil
    }
}
