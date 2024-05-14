//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
import Cocoa


/// An attributed string backed text element
protocol STAttributedTextElement: NSTextElement {
    var attributedString: NSAttributedString { get }
}

extension NSTextParagraph: STAttributedTextElement { }
