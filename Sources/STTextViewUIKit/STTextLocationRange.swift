//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

internal class STTextLocationRange: UITextRange {
    let textRange: NSTextRange

    init(textRange: NSTextRange) {
        self.textRange = textRange
    }

    override var debugDescription: String {
        textRange.description
    }

    override var start: UITextPosition {
        textRange.location.uiTextPosition
    }

    override var end: UITextPosition {
        textRange.endLocation.uiTextPosition
    }

    override var isEmpty: Bool {
        textRange.isEmpty
    }
}

internal extension NSTextRange {
    var uiTextRange: STTextLocationRange {
        STTextLocationRange(textRange: self)
    }
}

internal extension UITextRange {
    var nsTextRange: NSTextRange {
        guard let range = self as? STTextLocationRange else {
            fatalError("Invalid type")
        }
        return range.textRange
    }
}
