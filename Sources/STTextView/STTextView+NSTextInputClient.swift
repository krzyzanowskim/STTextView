//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSTextInputClient {

    @objc public func selectedRange() -> NSRange {
        if let selectionTextRange = textLayoutManager.textSelections.last?.textRanges.last {
            return NSRange(selectionTextRange, in: textContentManager)
        }

        return .notFound
    }


    // Managing Marked Text
    //
    // As the input context interprets keyboard input, it can mark incomplete input in a special way.
    // The text view displays this marked text differently from the selection, using temporary attributes
    // that affect only display, not layout or storage.
    //
    // One of the primary things that a text view must do to cooperate with an input context is to maintain
    // a (possibly empty) range of marked text within its text storage. The text view should highlight text
    // in this range in a distinctive way, and it should allow selection within the marked text.
    // A text view must also maintain an insertion point, which is usually at the end of the marked text,
    // but the user can place it within the marked text. The text view also maintains a (possibly empty)
    // selection range within its text storage, and if there is any marked text, the selection must be entirely
    // within the marked text

    /// Replaces a specified range in the receiver’s text storage with the given string and sets the selection.
    ///
    /// If there is no marked text, the current selection is replaced. If there is no selection, the string is inserted at the insertion point.
    /// When string is an NSString, the receiver is expected to render the marked text with distinguishing appearance (i.e. NSTextView renders with -markedTextAttributes).
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

        #if DEBUG
        logger.debug("\(#function) \(attributedString.string), selectedRange: \(selectedRange), replacementRange: \(replacementRange)")
        #endif

        let temporaryDisableUndoRegistration = undoManager?.isUndoRegistrationEnabled == true

        if replacementRange.location != NSNotFound {
            if markedText == nil {
                markedText = MarkedText(
                    markedText: attributedString.string,
                    markedRange: NSRange(location: replacementRange.location, length: attributedString.string.utf16.count)
                )

            } else if let markedText {
                markedText.markedText = attributedString.string
                markedText.markedRange = NSRange(location: replacementRange.location, length: attributedString.string.utf16.count)
            }
        } else if replacementRange.location == NSNotFound {
            // NSNotFound indicates that the marked text should be placed at the current insertion point
            // continue updates.dictation begins with this case

            if markedText == nil {
                markedText = MarkedText(
                    markedText: attributedString.string,
                    markedRange: NSRange(location: self.selectedRange().location, length: attributedString.string.utf16.count)
                )
            } else if let markedText {
                // Delete current marked range
                if let markedTextInsertRange = NSTextRange(markedText.markedRange, in: textContentManager) {
                    if temporaryDisableUndoRegistration {
                        undoManager?.disableUndoRegistration()
                    }

                    replaceCharacters(in: markedTextInsertRange, with: "")

                    if temporaryDisableUndoRegistration {
                        undoManager?.enableUndoRegistration()
                    }
                }

                markedText.markedText = attributedString.string
                markedText.markedRange = NSRange(location: markedText.markedRange.location, length: attributedString.string.utf16.count)
            }

            // Insert new marked text in place selected text - that is currently marked text range
            guard let markedTextInsertRange = NSTextRange(NSRange(location: markedText!.markedRange.location, length: 0), in: textContentManager) else {
                assertionFailure()
                return
            }

            if temporaryDisableUndoRegistration {
                undoManager?.disableUndoRegistration()
            }

            replaceCharacters(in: markedTextInsertRange, with: markedText!.markedText)

            if temporaryDisableUndoRegistration {
                undoManager?.enableUndoRegistration()
            }
        }
    }

    /// The receiver unmarks the marked text. If no marked text, the invocation of this method has no effect.
    ///
    /// The receiver removes any marking from pending input text and disposes of the marked text as it wishes.
    /// The text view should accept the marked text as if it had been inserted normally.
    /// If there is no marked text, the invocation of this method has no effect.
    @objc public func unmarkText() {
        if hasMarkedText() {
            if let markedTextRange = NSTextRange(markedText!.markedRange, in: textContentManager) {
                let temporaryDisableUndoRegistration = undoManager?.isUndoRegistrationEnabled == true

                if temporaryDisableUndoRegistration {
                    undoManager?.disableUndoRegistration()
                }

                replaceCharacters(in: markedTextRange, with: "")

                if temporaryDisableUndoRegistration {
                    undoManager?.enableUndoRegistration()
                }
            } else {
                assertionFailure()
            }
        }

        markedText = nil
    }

    /// Returns the marked range. Returns {NSNotFound, 0} if no marked range.
    ///
    /// The returned range measures from the start of the receiver’s text storage.
    /// The return value’s location is NSNotFound and its length is 0 if and only if hasMarkedText() returns false.
    @objc public func markedRange() -> NSRange {
        if !hasMarkedText() {
            return .notFound
        }

        return markedText!.markedRange
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
        unmarkText()

        var textRanges: [NSTextRange] = []

        if replacementRange == .notFound {
            textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
        }

        let replacementTextRange = NSTextRange(replacementRange, in: textContentManager)
        if let replacementTextRange, !textRanges.contains(where: { $0 == replacementTextRange }) {
            textRanges.append(replacementTextRange)
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
    }

}
