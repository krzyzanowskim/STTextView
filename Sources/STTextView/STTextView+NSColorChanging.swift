//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSColorChanging {

    public func changeColor(_ colorPanel: NSColorPanel?) {
        guard isEditable, let colorPanel = colorPanel else {
            return
        }

        if !textLayoutManager.insertionPointLocations.isEmpty {
            typingAttributes[.foregroundColor] = colorPanel.color
        } else {
            for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) where !textRange.isEmpty {
                addAttributes([.foregroundColor: colorPanel.color], range: textRange)
            }
        }
    }
}
