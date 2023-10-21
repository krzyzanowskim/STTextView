//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Updates the insertion point’s location and optionally restarts the blinking cursor timer.
    public func updateInsertionPointStateAndRestartTimer() {
        // Hide insertion point layers
        if shouldDrawInsertionPoint {
            let insertionPointsRanges = textLayoutManager.insertionPointSelections.flatMap(\.textRanges).filter(\.isEmpty)
            guard !insertionPointsRanges.isEmpty else {
                return
            }

            let textSelectionFrames = insertionPointsRanges.compactMap { textRange -> CGRect? in

                guard let textSegmentFrame = textLayoutManager.textSegmentFrame(in: textRange, type: .selection, options: .rangeNotRequired) else {
                    return nil
                }
                
                let selectionFrame = textSegmentFrame.intersection(frame)

                // because `textLayoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresExtraLineFragment, .ensuresLayout, .estimatesSize])`
                // returns unexpected value for extra line fragment height (return 14) that is not correct in the context,
                // therefore for empty override height with value manually calculated from font + paragraph style
                if textRange == textContentManager.documentRange, textRange.isEmpty {
                    return CGRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: typingLineHeight)).pixelAligned
                }

                return selectionFrame
            }

            removeInsertionPointView()

            for selectionFrame in textSelectionFrames where !selectionFrame.isNull && !selectionFrame.isInfinite {
                let insertionView = STInsertionPointView(frame: selectionFrame)
                insertionView.insertionPointColor = insertionPointColor

                if isFirstResponder {
                    insertionView.blinkStart()
                } else {
                    insertionView.blinkStop()
                }

                contentView.addSubview(insertionView)
            }
        } else if !shouldDrawInsertionPoint {
            removeInsertionPointView()
        }
    }

    func removeInsertionPointView() {
        contentView.subviews.removeAll { view in
            type(of: view) == insertionPointViewClass
        }
    }

}
