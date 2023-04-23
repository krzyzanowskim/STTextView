//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension NSTextContentManager {

    var documentString: String {
        var result: String = ""
        result.reserveCapacity(1024 * 4)

        enumerateTextElements(from: nil) { textElement in
            if let textParagraph = textElement as? NSTextParagraph {
                result += textParagraph.attributedString.string
            }

            return true
        }
        return result
    }


    func attributedString(in range: NSTextRange?) -> NSAttributedString? {
        let result = NSMutableAttributedString()
        if let range = range {
            // TODO: not performant for large documents
            //       instead process only affected elements and extract only the range
            //       Use enumerateTextElements and calculate attributed string range
            if let attributedString = attributedString(in: nil) {
                result.append(
                    attributedString.attributedSubstring(from: NSRange(range, in: self))
                )
            }
        } else {
            enumerateTextElements(from: nil) { textElement in
                if let textParagraph = textElement as? NSTextParagraph {
                    result.append(textParagraph.attributedString)
                }

                return true
            }
        }

        if result.length == 0 {
            return nil
        }

        return result
    }

}
