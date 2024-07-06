//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

package final class STMarkedText: CustomDebugStringConvertible {
    package var markedText: NSAttributedString
    package var markedRange: NSRange

    // Not used currently in STTextView.
    // that turned out to be good because it's buggy FB13789916 https://gist.github.com/krzyzanowskim/340c5810fc427e346b7c4b06d46b1e10
    package var selectedRange: NSRange

    package init(markedText: NSAttributedString, markedRange: NSRange, selectedRange: NSRange) {
        self.markedText = markedText
        self.markedRange = markedRange
        self.selectedRange = selectedRange
    }

    package var debugDescription: String {
        "markedText: \"\(markedText.string)\", markedRange: \(markedRange), selectedRange: \(selectedRange)"
    }
}
