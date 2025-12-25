//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

/// Wrapper for insertion point indicators.
///
/// STInsertionPointView
///      |---textInsertionIndicator (STInsertionPointIndicatorProtocol)
///
class STInsertionPointView: NSView {
    private let textInsertionIndicator: any STInsertionPointIndicatorProtocol

    override var isFlipped: Bool {
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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame frameRect: NSRect, textInsertionIndicator: STInsertionPointIndicatorProtocol) {
        self.textInsertionIndicator = textInsertionIndicator
        super.init(frame: frameRect)

        addSubview(textInsertionIndicator)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        // Manually reset size because `NSTextInsertionIndicator`
        // does not react to its autoresizingMask
        textInsertionIndicator.frame.size = newSize
    }

    func blinkStart() {
        textInsertionIndicator.blinkStart()
    }

    func blinkStop() {
        textInsertionIndicator.blinkStop()
    }

}
