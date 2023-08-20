//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import STTextKitPlus

extension NSTextContentManager {

    var documentString: String {
        var result: String = ""
        result.reserveCapacity(Int(PAGE_MAX_SIZE))

        enumerateTextElements(from: nil) { textElement in
            if let textParagraph = textElement as? NSTextParagraph {
                result += textParagraph.attributedString.string
            }

            return true
        }
        return result
    }

    /// Attributes at location
    func attributes(at location: NSTextLocation) -> [NSAttributedString.Key: Any] {
        guard !documentRange.isEmpty else {
            return [:]
        }

        let effectiveLocation: NSTextLocation
        if location == documentRange.location {
            effectiveLocation = location
        } else if location == documentRange.endLocation {
            effectiveLocation = self.location(location, offsetBy: -1) ?? location
        } else {
            effectiveLocation = location
        }

        // requires non-empty range
        return attributedString(
            in: NSTextRange(
                location: effectiveLocation,
                end: self.location(effectiveLocation, offsetBy: 1)
            )
        )?.attributes(
            at: 0,
            effectiveRange: nil
        ) ?? [:]
    }


}
