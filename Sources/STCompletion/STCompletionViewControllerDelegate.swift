//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

public protocol STCompletionViewControllerDelegate: AnyObject {
    func completionViewController<T: STCompletionViewControllerProtocol>(_ viewController: T, complete item: any STCompletionItem, movement: NSTextMovement)
}
