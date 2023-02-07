//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

extension STTextView {

    /// Updates the insertion point’s location and optionally restarts the blinking cursor timer.
    public func updateInsertionPointStateAndRestartTimer() {
        // Remove insertion point layers
        selectionLayer.sublayers?.removeAll(where: { layer in
            type(of: layer) == insertionPointLayerClass
        })

        if shouldDrawInsertionPoint {
            for textRange in textLayoutManager.insertionPointSelections.flatMap(\.textRanges) {
                textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: .rangeNotRequired) { ( _, textSegmentFrame, baselinePosition, _) in
                    var selectionFrame = textSegmentFrame.intersection(frame).pixelAligned
                    guard !selectionFrame.isNull, !selectionFrame.isInfinite else {
                        return true
                    }

                    // because `textLayoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresExtraLineFragment, .ensuresLayout, .estimatesSize])`
                    // returns unexpected value for extra line fragment height (return 14) that is not correct in the context,
                    // therefore for empty override height with value manually calculated from font + paragraph style
                    if textRange == textContentStorage.documentRange {
                        selectionFrame = NSRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: typingLineHeight)).pixelAligned
                    }

                    let insertionLayer = insertionPointLayerClass.init(frame: selectionFrame)
                    insertionLayer.insertionPointColor = insertionPointColor
                    insertionLayer.insertionPointWidth = insertionPointWidth
                    insertionLayer.updateGeometry()

                    if isFirstResponder {
                        insertionLayer.blinkStart()
                    } else {
                        insertionLayer.blinkStop()
                    }

                    selectionLayer.addSublayer(insertionLayer)

                    return true
                }
            }
        }
    }

}
