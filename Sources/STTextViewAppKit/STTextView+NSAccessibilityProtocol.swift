//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView  {

    open override func isAccessibilityElement() -> Bool {
        true
    }

    open override func isAccessibilityEnabled() -> Bool {
        isEditable || isSelectable
    }

    open override func accessibilityRole() -> NSAccessibility.Role? {
        .textArea
    }

    open override func accessibilityRoleDescription() -> String? {
        NSAccessibility.Role.description(for: self)
    }

    open override func accessibilityLabel() -> String? {
        NSLocalizedString("Text Editor", comment: "")
    }

    open override func accessibilityValue() -> Any? {
        text
    }

    open override func setAccessibilityValue(_ accessibilityValue: Any?) {
        guard let string = accessibilityValue as? String else {
            return
        }

        self.text = string
    }

    open override func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? {
        attributedSubstring(forProposedRange: range, actualRange: nil)
    }

    open override func accessibilityVisibleCharacterRange() -> NSRange {
        if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            return NSRange(viewportRange, in: textContentManager)
        }

        return NSRange()
    }

    open override func accessibilityString(for range: NSRange) -> String? {
        attributedSubstring(forProposedRange: range, actualRange: nil)?.string
    }

    open override func accessibilityNumberOfCharacters() -> Int {
        text?.count ?? 0
    }

    open override func accessibilitySelectedText() -> String? {
        textLayoutManager.textSelectionsString()
    }

    open override func accessibilitySelectedTextRange() -> NSRange {
        selectedRange()
    }

    open override func setAccessibilitySelectedTextRange(_ accessibilitySelectedTextRange: NSRange) {
        if let textRange = NSTextRange(accessibilitySelectedTextRange, in: textContentManager) {
            setSelectedTextRange(textRange, updateLayout: true)
        } else {
            assertionFailure()
        }
    }
}
