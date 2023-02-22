//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView  {

    open override func isAccessibilityElement() -> Bool {
        true
    }

    open override func accessibilityRole() -> NSAccessibility.Role? {
        .textArea
    }

    open override func accessibilityValue() -> Any? {
        string
    }

    open override func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? {
        attributedSubstring(forProposedRange: range, actualRange: nil)
    }

    open override func accessibilityVisibleCharacterRange() -> NSRange {
        if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            return NSRange(viewportRange, in: textContentStorage)
        }

        return NSRange()
    }

    open override func accessibilityString(for range: NSRange) -> String? {
        attributedSubstring(forProposedRange: range, actualRange: nil)?.string
    }

}
