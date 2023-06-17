//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSTextInputClient {

    @objc public func selectedRange() -> NSRange {
        if let selectionTextRange = textLayoutManager.textSelections.last?.textRanges.last {
            return NSRange(selectionTextRange, in: textContentManager)
        }

        return NSRange.notFound
    }

    /// Called by the input manager to set text which might be combined with further input to form the final text (e.g. composition of ^ and a to â).
    /// The receiver inserts string replacing the content specified by replacementRange.
    /// string can be either an NSString or NSAttributedString instance.
    /// selectedRange specifies the selection inside the string being inserted;
    /// hence, the location is relative to the beginning of string.
    /// When string is an NSString, the receiver is expected to render the marked text with distinguishing appearance (i.e. NSTextView renders with -markedTextAttributes).
    ///
    /// The receiver inserts string replacing the content specified by replacementRange.
    /// string can be either an NSString or NSAttributedString instance.
    /// selectedRange specifies the selection inside the string being inserted; hence, the location is relative to the beginning of string.
    /// When string is an NSString, the receiver is expected to render the marked text with distinguishing appearance (i.e. NSTextView renders with -markedTextAttributes).

    /// Replaces a specified range in the receiver’s text storage with the given string and sets the selection.
    ///
    /// If there is no marked text, the current selection is replaced. If there is no selection, the string is inserted at the insertion point.
    /// - Parameters:
    ///   - string: The string to insert. Can be either an NSString or NSAttributedString instance.
    ///   - selectedRange: The range to set as the selection, computed from the beginning of the inserted string.
    ///   - replacementRange: The range to replace, computed from the beginning of the marked text.
    @objc public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        let attributedString: NSAttributedString
        switch string {
        case is NSAttributedString:
            attributedString = string as! NSAttributedString
        case is String:
            attributedString = NSAttributedString(string: string as! String, attributes: markedTextAttributes ?? typingAttributes)
        default:
            assertionFailure()
            return
        }

        if let markedText {
            markedText.string = string
            markedText.selectedRange = selectedRange
        } else if attributedString.length > 0 {
            markedText = MarkedText(
                string: string,
                selectedRange: selectedRange,
                replacementRange: replacementRange
            )
        }

        guard let markedText = markedText,
              let replacementTextRange = NSTextRange(markedText.replacementRange, in: textContentManager) else {
            return
        }

        replaceCharacters(in: replacementTextRange, with: attributedString, allowsTypingCoalescing: false)
    }

    /// The receiver unmarks the marked text. If no marked text, the invocation of this method has no effect.
    ///
    /// The receiver removes any marking from pending input text and disposes of the marked text as it wishes.
    /// The text view should accept the marked text as if it had been inserted normally.
    /// If there is no marked text, the invocation of this method has no effect.
    @objc public func unmarkText() {
        if hasMarkedText() {
            // TODO: The text view should accept the marked text as if it had been inserted normally.
        }

        markedText = nil
    }

    /// Returns the marked range. Returns {NSNotFound, 0} if no marked range.
    @objc public func markedRange() -> NSRange {
        markedText?.replacementRange ?? .notFound
    }

    /// Returns whether or not the receiver has marked text.
    @objc public func hasMarkedText() -> Bool {
        markedText != nil
    }

    @objc public func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        textContentManager.attributedString(in: NSTextRange(range, in: textContentManager))
    }

    @objc public func attributedString() -> NSAttributedString {
        textContentManager.attributedString(in: nil) ?? NSAttributedString()
    }

    @objc public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        [.backgroundColor, .foregroundColor, .font]
    }

    @objc public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return .zero
        }

        var rect: NSRect = .zero
        textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: .rangeNotRequired) { _, textSegmentFrame, baselinePosition, textContainer in
            rect = window!.convertToScreen(convert(textSegmentFrame, to: nil))
            return false
        }

        return rect
    }

    @objc public func characterIndex(for point: NSPoint) -> Int {
        guard let textLayoutFragment = textLayoutManager.textLayoutFragment(for: point) else {
            return NSNotFound
        }

        return textLayoutManager.offset(
            from: textLayoutManager.documentRange.location, to: textLayoutFragment.rangeInElement.location
        )
    }

    @objc open func insertText(_ string: Any, replacementRange: NSRange) {
        var textRanges: [NSTextRange]

        if hasMarkedText() {
            textRanges = [NSTextRange(markedText!.replacementRange, in: textContentManager)!]
        } else if replacementRange == .notFound {
            textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
        } else {
            textRanges = []
        }

        let replacementTextRange = NSTextRange(replacementRange, in: textContentManager)
        if let replacementTextRange, !textRanges.contains(where: { $0 == replacementTextRange }) {
            textRanges.append(replacementTextRange)
        }

        let temporaryDisableUndoRegistration = hasMarkedText() && undoManager?.isUndoRegistrationEnabled == true
        if temporaryDisableUndoRegistration {
            undoManager?.disableUndoRegistration()
        }

        switch string {
        case let string as String:
            if shouldChangeText(in: textRanges, replacementString: string) {
                replaceCharacters(in: textRanges, with: string, useTypingAttributes: true, allowsTypingCoalescing: true)
            }
        case let attributedString as NSAttributedString:
            if shouldChangeText(in: textRanges, replacementString: attributedString.string) {
                replaceCharacters(in: textRanges, with: attributedString, allowsTypingCoalescing: true)
            }
        default:
            assertionFailure()
        }

        if hasMarkedText() {
            if temporaryDisableUndoRegistration {
                undoManager?.enableUndoRegistration()
            }
            unmarkText()
        }
    }

}
