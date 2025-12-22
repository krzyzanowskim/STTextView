//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

public protocol STCompletionViewControllerDelegate: AnyObject {
    func completionViewController(_ viewController: some STCompletionViewControllerProtocol, complete item: any STCompletionItem, movement: NSTextMovement)
    func completionViewControllerCancel(_ viewController: some STCompletionViewControllerProtocol)
}
