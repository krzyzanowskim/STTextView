//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension NSTextRange {

    public convenience init?(_ nsRange: NSRange, in textContentManager: NSTextContentManager) {
        guard let start = textContentManager.location(textContentManager.documentRange.location, offsetBy: nsRange.location) else {
            return nil
        }
        let end = textContentManager.location(start, offsetBy: nsRange.length)
        self.init(location: start, end: end)
    }

    public func length(in textContentManager: NSTextContentManager) -> Int {
        textContentManager.offset(from: location, to: endLocation)
    }

    /// Returns a copy of this range clamped to the given limiting range.
    public func clamped(to textRange: NSTextRange) -> Self? {
        let beginLocation = {
            if self.location <= textRange.location {
                return textRange.location
            }

            if self.location >= textRange.endLocation {
                return textRange.endLocation
            }

            return self.location
        }()

        let endLocation = {
            if self.endLocation <= textRange.location {
                return textRange.location
            }

            if self.endLocation >= textRange.endLocation {
                return textRange.endLocation
            }

            return self.endLocation
        }()

        return Self(location: beginLocation, end: endLocation)
    }
}
