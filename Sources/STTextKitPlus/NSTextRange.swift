//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

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
}
