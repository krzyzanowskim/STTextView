//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// An attributed string backed text element
package protocol STAttributedTextElement: NSTextElement {
    var attributedString: NSAttributedString { get }
}

extension NSTextParagraph: STAttributedTextElement { }
