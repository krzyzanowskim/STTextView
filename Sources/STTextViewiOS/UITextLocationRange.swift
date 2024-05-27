//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

internal class UITextLocationRange: UITextRange {
    let textRange: NSTextRange

    override var debugDescription: String {
        textRange.description
    }

    init(textRange: NSTextRange) {
        self.textRange = textRange
    }
}

internal extension NSTextRange {
    var uiTextRange: UITextLocationRange {
        UITextLocationRange(textRange: self)
    }
}

internal extension UITextRange {
    var nsTextRange: NSTextRange {
        guard let range = self as? UITextLocationRange else {
            fatalError("Invalid type")
        }
        return range.textRange
    }
}
