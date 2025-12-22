//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus


/// NSAccessibility
extension STTextView {
    override open func accessibilitySharedCharacterRange() -> NSRange {
        NSRange(textContentManager.documentRange, in: textContentManager)
    }
}


/// NSAccessibilityProtocol
extension STTextView {

    override open func isAccessibilityElement() -> Bool {
        true
    }

    override open func isAccessibilityEnabled() -> Bool {
        isEditable || isSelectable
    }

    override open func accessibilityRole() -> NSAccessibility.Role? {
        .textArea
    }

    override open func accessibilityRoleDescription() -> String? {
        NSAccessibility.Role.description(for: self)
    }

    override open func accessibilityLabel() -> String? {
        NSLocalizedString("Text Editor", comment: "")
    }

    override open func accessibilityNumberOfCharacters() -> Int {
        text?.count ?? 0
    }

    override open func accessibilitySelectedText() -> String? {
        textLayoutManager.textSelectionsString()
    }

    override open func setAccessibilitySelectedText(_ accessibilitySelectedText: String?) {
        self.replaceCharacters(in: selectedRange(), with: accessibilitySelectedText ?? "")
    }

    override open func accessibilitySelectedTextRange() -> NSRange {
        selectedRange()
    }

    override open func setAccessibilitySelectedTextRanges(_ accessibilitySelectedTextRanges: [NSValue]?) {
        for range in accessibilitySelectedTextRanges?.map(\.rangeValue) ?? [] {
            self.setSelectedRange(range)
        }
    }

    override open func isAccessibilityFocused() -> Bool {
        isFirstResponder && isSelectable
    }

    override open func setAccessibilityFocused(_ accessibilityFocused: Bool) {
        if !accessibilityFocused, isFirstResponder {
            window?.makeFirstResponder(nil)
        } else if accessibilityFocused {
            window?.makeFirstResponder(self)
        }
    }
}

extension STTextView {

    // NSAccessibilityStaticText

    override open func accessibilityVisibleCharacterRange() -> NSRange {
        if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            return NSRange(viewportRange, in: textContentManager)
        }

        return NSRange()
    }

    override open func setAccessibilitySelectedTextRange(_ accessibilitySelectedTextRange: NSRange) {
        guard let textRange = NSTextRange(accessibilitySelectedTextRange, in: textContentManager) else {
            assertionFailure()
            return
        }
        setSelectedTextRange(textRange, updateLayout: true)
    }

    override open func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? {
        attributedSubstring(forProposedRange: range, actualRange: nil)
    }

    override open func accessibilityValue() -> Any? {
        text
    }

    override open func setAccessibilityValue(_ accessibilityValue: Any?) {
        guard let string = accessibilityValue as? String else {
            return
        }

        self.text = string
    }

    // NSAccessibilityNavigableStaticText

    override open func accessibilityFrame(for range: NSRange) -> NSRect {
        guard let textRange = NSTextRange(range, in: textContentManager),
              let segmentFrame = textLayoutManager.textSegmentFrame(in: textRange, type: .standard)
        else {
            return .zero
        }
        return window?.convertToScreen(contentView.convert(segmentFrame, to: nil)) ?? .zero
    }

    override open func accessibilityLine(for index: Int) -> Int {
        guard let location = textContentManager.location(at: index),
              let position = textContentManager.position(location)
        else {
            return 0
        }
        return position.row
    }

    override open func accessibilityRange(forLine line: Int) -> NSRange {
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

    override open func accessibilityString(for range: NSRange) -> String? {
        attributedSubstring(forProposedRange: range, actualRange: nil)?.string
    }
}
