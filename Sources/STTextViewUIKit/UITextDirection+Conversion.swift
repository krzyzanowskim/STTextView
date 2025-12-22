//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension UITextDirection {
    var textSelectionNavigationDirection: NSTextSelectionNavigation.Direction {
        switch self.rawValue {
        case UITextLayoutDirection.right.rawValue:
            .right
        case UITextLayoutDirection.left.rawValue:
            .left
        case UITextLayoutDirection.up.rawValue:
            .up
        case UITextLayoutDirection.down.rawValue:
            .down
        case UITextStorageDirection.forward.rawValue:
            .forward
        case UITextStorageDirection.backward.rawValue:
            .backward
        default:
            NSTextSelectionNavigation.Direction(rawValue: self.rawValue)!
        }
    }
}

extension UITextLayoutDirection {
    var textSelectionNavigationDirection: NSTextSelectionNavigation.Direction {
        switch self {
        case .up:
            .up
        case .down:
            .down
        case .left:
            .left
        case .right:
            .right
        @unknown default:
            NSTextSelectionNavigation.Direction(rawValue: self.rawValue)!
        }
    }
}

extension UITextStorageDirection {
    var textSelectionNavigationDirection: NSTextSelectionNavigation.Direction {
        switch self {
        case .forward:
            .forward
        case .backward:
            .backward
        @unknown default:
            NSTextSelectionNavigation.Direction(rawValue: self.rawValue)!
        }
    }
}
