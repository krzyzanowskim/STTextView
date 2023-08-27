//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

public protocol STCompletionViewControllerProtocol: NSViewController {
    typealias Item = any STCompletionItem
    var items: [Item] { get set }
    var delegate: STCompletionViewControllerDelegate? { get set }
}
