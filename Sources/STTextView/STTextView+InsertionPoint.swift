//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

extension STTextView {

    /// Updates the insertion point’s location and optionally restarts the blinking cursor timer.
    public func updateInsertionPointStateAndRestartTimer() {
        // Remove insertion point layers
        selectionView.subviews.removeAll(where: { view in
            type(of: view) == STTextInsertionIndicator.self
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
                    if textRange == textContentManager.documentRange {
                        selectionFrame = NSRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: typingLineHeight)).pixelAligned
                    }

                    let insertionView = STTextInsertionIndicator(frame: selectionFrame)
                    if let insertionPointColor {
                        insertionView.color = insertionPointColor
                    }
                    insertionView.effectsViewInserter = { [weak self] view in
                        // FIXME: Never called
                        self?.selectionView.addSubview(view)
                    }
                    selectionView.addSubview(insertionView)

                    return true
                }
            }
        }
    }

}
