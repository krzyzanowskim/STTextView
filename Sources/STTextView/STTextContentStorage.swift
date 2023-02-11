//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class STTextContentStorage: NSTextContentStorage {

    override func replaceContents(in range: NSTextRange, with textElements: [NSTextElement]?) {

        guard let paragraphElements = textElements?.compactMap({ $0 as? NSTextParagraph }) else {
            // Non-functional (FB9925647)
            super.replaceContents(in: range, with: textElements)
            assertionFailure()
            return
        }

        let replacementString = paragraphElements.map(\.attributedString).reduce(into: NSMutableAttributedString()) { partialResult, attributedString in
            partialResult.append(attributedString)
        }

        textStorage?.replaceCharacters(
            in: NSRange(range, in: self),
            with: replacementString
        )
    }

}
