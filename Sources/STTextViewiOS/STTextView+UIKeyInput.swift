//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension STTextView: UIKeyInput {

    public var hasText: Bool {
        !textContentManager.documentRange.isEmpty
    }

    public func insertText(_ text: String) {
        let textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
        if shouldChangeText(in: textRanges, replacementString: text) {
            replaceCharacters(in: textRanges, with: text, useTypingAttributes: true, allowsTypingCoalescing: true)
        }
    }

    public func deleteBackward() {
        assertionFailure("Not Implemented")
    }

}
