//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

extension STTextView {

    /// Updates the insertion point’s location and optionally restarts the blinking cursor timer.
    public func updateInsertionPointStateAndRestartTimer() {
        // Hide insertion point layers
        if shouldDrawInsertionPoint {
            for textRange in textLayoutManager.insertionPointSelections.flatMap(\.textRanges) where textRange.isEmpty {
                textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: .rangeNotRequired) { ( _, textSegmentFrame, baselinePosition, _) in
                    var selectionFrame = textSegmentFrame.intersection(frame)
                    guard !selectionFrame.isNull, !selectionFrame.isInfinite else {
                        return true
                    }

                    // because `textLayoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresExtraLineFragment, .ensuresLayout, .estimatesSize])`
                    // returns unexpected value for extra line fragment height (return 14) that is not correct in the context,
                    // therefore for empty override height with value manually calculated from font + paragraph style
                    if textRange == textContentManager.documentRange {
                        selectionFrame = NSRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: selectionFrame.height)).pixelAligned
                    }

                    let insertionView = insertionPointViewClass.init(frame: selectionFrame)
                    insertionView.insertionPointColor = insertionPointColor
                    insertionView.insertionPointWidth = insertionPointWidth
                    insertionView.updateGeometry()

                    if isFirstResponder {
                        insertionView.blinkStart()
                    } else {
                        insertionView.blinkStop()
                    }

                    if !contentView.subviews.contains(where: { type(of: $0) == insertionPointViewClass }) {
                        contentView.addSubview(insertionView)
                    }

                    return true
                }
            }
        } else {
            contentView.subviews.removeAll { view in
                type(of: view) == insertionPointViewClass
            }
        }
    }

}
