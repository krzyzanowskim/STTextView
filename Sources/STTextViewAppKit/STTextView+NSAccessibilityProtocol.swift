//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

/// NSAccessibilityProtocol
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

    open override func accessibilityNumberOfCharacters() -> Int {
        text?.count ?? 0
    }

    open override func accessibilitySelectedText() -> String? {
        textLayoutManager.textSelectionsString()
    }

    open override func accessibilitySelectedTextRange() -> NSRange {
        selectedRange()
    }

    open override func isAccessibilityFocused() -> Bool {
        isFirstResponder && isSelectable
    }
}

extension STTextView  {

    // NSAccessibilityStaticText

    open override func accessibilityVisibleCharacterRange() -> NSRange {
        if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            return NSRange(viewportRange, in: textContentManager)
        }

        return NSRange()
    }

    open override func setAccessibilitySelectedTextRange(_ accessibilitySelectedTextRange: NSRange) {
        guard let textRange = NSTextRange(accessibilitySelectedTextRange, in: textContentManager) else {
            assertionFailure()
            return
        }
        setSelectedTextRange(textRange, updateLayout: true)
    }

    open override func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? {
        attributedSubstring(forProposedRange: range, actualRange: nil)
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

    // NSAccessibilityNavigableStaticText

    open override func accessibilityFrame(for range: NSRange) -> NSRect {
        guard let textRange = NSTextRange(range, in: textContentManager),
              let segmentFrame = textLayoutManager.textSegmentFrame(in: textRange, type: .standard)
        else {
            return .zero
        }
        return window?.convertToScreen(contentView.convert(segmentFrame, to: nil)) ?? .zero
    }

    open override func accessibilityLine(for index: Int) -> Int {
        guard let location = textContentManager.location(at: index),
              let position = textContentManager.position(location)
        else {
            return 0
        }
        return position.row
    }

    open override func accessibilityRange(forLine line: Int) -> NSRange {
        guard let location = textContentManager.location(line: line) else {
            return .notFound
        }

        var textElement: NSTextElement?
        textContentManager.enumerateTextElements(from: location) { element in
            textElement = element
            return false
        }

        guard let textElement, let textElementRange = textElement.elementRange else {
            return .notFound
        }

        return NSRange(textElementRange, in: textContentManager)
    }

    open override func accessibilityString(for range: NSRange) -> String? {
        attributedSubstring(forProposedRange: range, actualRange: nil)?.string
    }

}
