//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class STTextContentStorage: NSTextContentStorage {

    override func replaceContents(in range: NSTextRange, with textElements: [NSTextElement]?) {
        // TODO: Non-functional (FB9925647)
        assertionFailure()
        super.replaceContents(in: range, with: textElements)
    }

}
