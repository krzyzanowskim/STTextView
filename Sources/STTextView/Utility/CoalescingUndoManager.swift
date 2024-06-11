//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

final class CoalescingUndoManager: UndoManager {

    private var lastRange: NSTextRange?

    private var isCoalescing: Bool = false

    override init() {
        super.init()
        self.runLoopModes = [.default, .common, .eventTracking, .modalPanel]
        self.groupsByEvent = false
    }

    override func undo() {
        if isCoalescing {
            endCoalescing()
        }
        super.undo()
    }

    override func redo() {
        if isCoalescing {
            endCoalescing()
        }
        super.redo()
    }

    func checkCoalescing(range: NSTextRange) {
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

    func startCoalescing() {
        guard !isCoalescing else { return }
        isCoalescing = true
        beginUndoGrouping()
    }

    func endCoalescing() {
        guard isCoalescing else { return }
        isCoalescing = false
        lastRange = nil
        endUndoGrouping()
    }
}
