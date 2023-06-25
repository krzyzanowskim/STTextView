//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSDraggingSource {

    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : .move
    }

    public func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        logger.debug("\(#function)")
    }

    public func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        logger.debug("\(#function), screenPoint: \(screenPoint.debugDescription)")
    }

    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        logger.debug("\(#function), screenPoint: \(screenPoint.debugDescription), operation: \(operation.rawValue)")
        cleanUpAfterDragOperation()
    }
}
