//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

/// akin to NSText
@objc public protocol STText {
    var string: String? { get set }

    var font: NSFont? { get set }

    var isEditable: Bool { get set }
    var isSelectable: Bool { get set }

    var textColor: NSColor? { get set }
    var defaultParagraphStyle: NSParagraphStyle? { get set }
    var typingAttributes: [NSAttributedString.Key: Any] { get set }

    weak var delegate: STTextViewDelegate? { get set }

    func didChangeText()
}
