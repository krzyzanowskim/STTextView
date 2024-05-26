//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

package extension NSAttributedString {
    func attributes(in range: NSRange, options: NSAttributedString.EnumerationOptions = []) -> Set<NSAttributedString.Key> {
        var usedAttributes: Set<NSAttributedString.Key> = []

        enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired) { attrs, _, _ in
            // enumeration block executed at least once without a good reason FB12863947
            // https://gist.github.com/krzyzanowskim/1c07715c5193382562b2e597379a8e4b
            if !attrs.isEmpty {
                usedAttributes.formUnion(attrs.keys)
            }
        }
        return usedAttributes
    }

    func attribute(_ attrName: NSAttributedString.Key, in range: NSRange, options: NSAttributedString.EnumerationOptions = []) -> [(range: NSRange, value: Any?)] {
        var ranges: [(range: NSRange, value: Any?)] = []
        enumerateAttribute(attrName, in: range, options: options) { value, range, _ in
            // enumeration block executed at least once without a good reason FB12863947
            // https://gist.github.com/krzyzanowskim/1c07715c5193382562b2e597379a8e4b
            if value != nil {
                ranges.append((range: range, value: value))
            }
        }
        return ranges
    }

    var range: NSRange {
        NSRange(location: 0, length: length)
    }

    var isEmpty: Bool {
        length == 0
    }
}
