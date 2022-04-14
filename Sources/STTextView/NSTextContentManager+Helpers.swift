//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension NSTextContentManager {

    var documentString: String {
        var result: String = ""
        result.reserveCapacity(1024 * 4)

        enumerateTextElements(from: nil, options: []) { textElement in
            if let textParagraph = textElement as? NSTextParagraph {
                result += textParagraph.attributedString.string
            }

            return true
        }
        return result
    }

}
