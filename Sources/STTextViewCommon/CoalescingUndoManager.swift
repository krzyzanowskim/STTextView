//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

import STTextKitPlus

package class CoalescingUndoManager: UndoManager {

    private var lastRange: NSTextRange?

    private var isCoalescing: Bool = false

    package override init() {
        super.init()
        #if os(macOS)
        self.runLoopModes = [.default, .common, .eventTracking, .modalPanel]
        #else
        self.runLoopModes = [.default, .common, .tracking]
        #endif
        self.groupsByEvent = false
    }

    package override func undo() {
        if isCoalescing {
            endCoalescing()
        }
        super.undo()
    }

    package override func redo() {
        if isCoalescing {
            endCoalescing()
        }
        super.redo()
    }

    package func checkCoalescing(range: NSTextRange) {
        defer {
            lastRange = range
        }
        guard isCoalescing, let lastRange else {
            startCoalescing()
            return
        }
        if !lastRange.intersects(range) && lastRange.endLocation != range.location {
            endCoalescing()
            startCoalescing()
        }
    }

    package func startCoalescing() {
        guard !isCoalescing else { return }
        isCoalescing = true
        beginUndoGrouping()
    }

    package func endCoalescing() {
        guard isCoalescing else { return }
        isCoalescing = false
        lastRange = nil
        endUndoGrouping()
    }
}
