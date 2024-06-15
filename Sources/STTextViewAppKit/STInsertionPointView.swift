//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

/// Wrapper for insertion point indicators.
///
/// STInsertionPointView
///      |---textInsertionIndicator (STInsertionPointIndicatorProtocol)
///
internal class STInsertionPointView: NSView {
    private var textInsertionIndicator: any STInsertionPointIndicatorProtocol

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

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame frameRect: NSRect, textInsertionIndicator: STInsertionPointIndicatorProtocol) {
        self.textInsertionIndicator = textInsertionIndicator
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
