//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

class STTextLocationRange: UITextRange {
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

extension NSTextRange {
    var uiTextRange: STTextLocationRange {
        STTextLocationRange(textRange: self)
    }
}

extension UITextRange {
    var nsTextRange: NSTextRange {
        guard let range = self as? STTextLocationRange else {
            fatalError("Invalid type")
        }
        return range.textRange
    }
}
