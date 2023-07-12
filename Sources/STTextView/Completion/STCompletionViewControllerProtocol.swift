//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

public protocol STCompletionViewControllerProtocol: NSViewController {
    var items: [any STCompletionItem] { get set }
    var delegate: STCompletionViewControllerDelegate? { get set }
}
