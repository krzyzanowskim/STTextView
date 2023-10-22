//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

open class STInsertionPointView: NSView {
    private var textInsertionIndicator: any STInsertionPointProtocol

    open override var isFlipped: Bool {
        true
    }

    var insertionPointColor: NSColor {
        get {
            textInsertionIndicator.insertionPointColor
        }

        set {
            textInsertionIndicator.insertionPointColor = newValue
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect) {
        if #available(macOS 14, *) {
            textInsertionIndicator = STTextInsertionIndicatorNew(frame: CGRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height))
        } else {
            textInsertionIndicator = STTextInsertionIndicatorOld(frame: CGRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height))
        }

        super.init(frame: frameRect)

        addSubview(textInsertionIndicator)
    }

    func blinkStart() {
        textInsertionIndicator.blinkStart()
    }

    func blinkStop() {
        textInsertionIndicator.blinkStop()
    }

}

private protocol STInsertionPointProtocol: NSView {
    var insertionPointColor: NSColor { get set }

    func blinkStart()
    func blinkStop()
}

@available(macOS 14.0, *)
private class STTextInsertionIndicatorNew: NSTextInsertionIndicator, STInsertionPointProtocol {

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var insertionPointColor: NSColor {
        get {
            color
        }

        set {
            color = newValue
        }
    }

    func blinkStart() {
        displayMode = .automatic
    }

    func blinkStop() {
        displayMode = .hidden
    }

    open override var isFlipped: Bool {
        true
    }
}

private class STTextInsertionIndicatorOld: NSView, STInsertionPointProtocol {
    private var timer: Timer?

    var insertionPointColor: NSColor = .defaultTextInsertionPoint {
        didSet {
            layer?.backgroundColor = insertionPointColor.cgColor
        }
    }

    override init(frame frameRect: CGRect) {
        var indicatorRect = frameRect
        indicatorRect.size.width = 2
        super.init(frame: indicatorRect)

        wantsLayer = true
        layer?.backgroundColor = insertionPointColor.withAlphaComponent(0.9).cgColor
        layer?.cornerRadius = 1
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func blinkStart() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            self?.isHidden.toggle()
        }
    }
    
    func blinkStop() {
        isHidden = false
        timer?.invalidate()
        timer = nil
    }
    
    open override var isFlipped: Bool {
        true
    }
}

