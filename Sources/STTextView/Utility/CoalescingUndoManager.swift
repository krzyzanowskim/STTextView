//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

final class CoalescingUndoManager: UndoManager {

    private var lastRange: NSTextRange?

    var isCoalescing: Bool {
        lastRange != nil
    }

    override init() {
        super.init()
        self.runLoopModes = [.default, .common, .eventTracking, .modalPanel]
        self.groupsByEvent = false
    }

    override func undo() {
        if groupingLevel == 1 {
            endUndoGrouping()
        }
        super.undo()
    }

    override func redo() {
        if groupingLevel == 1 {
            endUndoGrouping()
        }
        super.redo()
    }

    func checkCoalescing(range: NSTextRange) {
        defer {
            lastRange = range
        }
        guard let lastRange else {
            beginUndoGrouping()
            return
        }
        if !lastRange.intersects(range) && lastRange.endLocation != range.location {
            endCoalescing()
            beginUndoGrouping()
        }
    }

    func endCoalescing() {
        guard groupingLevel > 0 else { return }
        lastRange = nil
        endUndoGrouping()
    }
}
