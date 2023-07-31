//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

extension NSAttributedString {
    func attributes(in range: NSRange) -> Set<NSAttributedString.Key> {
        var usedAttributes: Set<NSAttributedString.Key> = []
        enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired) { attrs, _, _ in
            usedAttributes.formUnion(attrs.keys)
        }
        return usedAttributes
    }

    var range: NSRange {
        NSRange(location: 0, length: length)
    }
}
