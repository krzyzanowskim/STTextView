//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextViewCommon

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
        let attributedMarkedString: NSAttributedString
        switch string {
        case let attributedString as NSAttributedString:
            let attributedString = NSMutableAttributedString(attributedString: attributedString)

            // it comes with unexpected NSUnderlineColorAttributeName with a clear color that makes it not visible
            // probably it should be more sophisticated to care about the clear underline and do something about
            // but I don't really know how to test this scenario, hence remove clear underline
            attributedString.removeAttribute(.underlineColor, range:  NSRange(location: 0, length: attributedString.length))

            let attrs = typingAttributes.merging(markedTextAttributes) { (_, new) in new }
            attributedString.addAttributes(attrs, range: NSRange(location: 0, length: attributedString.length))
            attributedMarkedString = attributedString
        case let string as String:
            let attrs = typingAttributes.merging(markedTextAttributes) { (_, new) in new }
            attributedMarkedString = NSAttributedString(string: string, attributes: attrs)
        default:
            assertionFailure()
            return
        }

        #if DEBUG
        logger.debug("\(#function) \(attributedMarkedString.string), selectedRange: \(selectedRange), replacementRange: \(replacementRange)")
        #endif

        if replacementRange.location != NSNotFound {
            if markedText == nil {
                self.markedText = STMarkedText(
                    markedText: attributedMarkedString,
                    markedRange: NSRange(location: replacementRange.location, length: attributedMarkedString.length),
                    selectedRange: NSRange(location: replacementRange.location + selectedRange.location, length: selectedRange.length)
                )

            } else if let markedText {
                markedText.markedText = attributedMarkedString
                markedText.markedRange = NSRange(location: replacementRange.location, length: attributedMarkedString.length)
                markedText.selectedRange = NSRange(location: replacementRange.location + selectedRange.location, length: selectedRange.length)
            }
        } else if replacementRange.location == NSNotFound {
            // NSNotFound indicates that the marked text should be placed at the current insertion point
            // continue updates.dictation begins with this case

            if markedText == nil {
                self.markedText = STMarkedText(
                    markedText: attributedMarkedString,
                    markedRange: NSRange(location: self.selectedRange().location, length: attributedMarkedString.length),
                    selectedRange: NSRange(location: self.selectedRange().location + selectedRange.location, length: selectedRange.length)
                )
            } else if let markedText {
                // Delete current marked range
                undoManager.withoutUndoRegistration {
                    replaceCharacters(in: NSTextRange(markedText.markedRange, in: textContentManager)!, with: "")
                }

                // update
                markedText.markedText = attributedMarkedString
                markedText.markedRange = NSRange(location: markedText.markedRange.location, length: attributedMarkedString.length)
                markedText.selectedRange = NSRange(location: markedText.markedRange.location + selectedRange.location, length: selectedRange.length)
            }
        }

        // Insert new marked text (or replace replacementRange)
        let insertionRangeLenght = replacementRange.location == NSNotFound ? 0 : replacementRange.length
        let insertionRange = NSRange(location: markedText!.markedRange.location, length: insertionRangeLenght)
        undoManager.withoutUndoRegistration {
            replaceCharacters(in: NSTextRange(insertionRange, in: textContentManager)!, with: markedText!.markedText, allowsTypingCoalescing: false)
        }
    }

    /// The receiver unmarks the marked text. If no marked text, the invocation of this method has no effect.
    ///
    /// The receiver removes any marking from pending input text and disposes of the marked text as it wishes.
    /// The text view should accept the marked text as if it had been inserted normally.
    /// If there is no marked text, the invocation of this method has no effect.
    @objc public func unmarkText() {
        if hasMarkedText() {
            // Delete temporary marked text. It's been replaced with final text in insertText
            undoManager.withoutUndoRegistration {
                let markedTextRange = NSTextRange(markedText!.markedRange, in: textContentManager)!
                replaceCharacters(in: markedTextRange, with: "")
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
        // An implementation of this method should be prepared for range to be out of bounds.
        let location = textLayoutManager.location(textLayoutManager.documentRange.location, offsetBy: range.location) ?? textLayoutManager.documentRange.location
        let endLocation = textLayoutManager.location(textLayoutManager.documentRange.location, offsetBy: range.location + range.length) ?? textLayoutManager.documentRange.endLocation

        guard let textRange = NSTextRange(location: location, end: endLocation), !textRange.isEmpty else {
            return nil
        }

        actualRange?.pointee = NSRange(textRange, in: textContentManager)

        return textContentManager.attributedString(in: textRange)
    }

    @objc public func attributedString() -> NSAttributedString {
        textContentManager.attributedString(in: nil) ?? NSAttributedString()
    }

    /// Returns an array of attribute names recognized by the receiver.
    ///
    /// Returns an empty array if no attributes are supported.
    @objc public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        [
            .underlineStyle,
            .underlineColor,
            .markedClauseSegment,
            NSAttributedString.Key("NSTextInputReplacementRangeAttributeName")
        ]
    }

    @objc public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return .zero
        }

        var rect: CGRect = .zero
        textLayoutManager.enumerateTextSegments(in: textRange, type: .standard, options: .rangeNotRequired) { _, textSegmentFrame, baselinePosition, textContainer in
            rect = window!.convertToScreen(contentView.convert(textSegmentFrame, to: nil))
            return false
        }

        return rect
    }

    @objc public func characterIndex(for point: CGPoint) -> Int {
        let eventPoint = contentView.convert(window!.convertPoint(fromScreen: point), from: nil)
        guard let location = textLayoutManager.location(interactingAt: eventPoint, inContainerAt: textLayoutManager.documentRange.location) else {
            return NSNotFound
        }

        return textLayoutManager.offset(from: textLayoutManager.documentRange.location, to: location)
    }

    @objc open func insertText(_ string: Any, replacementRange: NSRange) {
        unmarkText()

        var textRanges: [NSTextRange] = []

        if replacementRange == .notFound {
            textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
            assert(!textRanges.isEmpty, "Unknown selection range to insert")
        }

        let replacementTextRange = NSTextRange(replacementRange, in: textContentManager)
        if let replacementTextRange, !textRanges.contains(where: { $0 == replacementTextRange }) {
            textRanges.append(replacementTextRange)
        }

        switch string {
        case let string as String:
            if shouldChangeText(in: textRanges, replacementString: string) {
                replaceCharacters(in: textRanges, with: string, useTypingAttributes: true, allowsTypingCoalescing: true)
                updateTypingAttributes()
            }
        case let attributedString as NSAttributedString:
            if shouldChangeText(in: textRanges, replacementString: attributedString.string) {
                replaceCharacters(in: textRanges, with: attributedString, allowsTypingCoalescing: true)
                updateTypingAttributes()
            }
        default:
            assertionFailure()
        }
    }

    // TODO: Adopting the system text cursor in custom text views
    // https://developer.apple.com/documentation/appkit/text_display/adopting_the_system_text_cursor_in_custom_text_views
}


private extension Optional<UndoManager> {
    func withoutUndoRegistration(_ action: () -> Void) {
        let temporaryDisableUndoRegistration = self?.isUndoRegistrationEnabled == true

        if let self {
            if temporaryDisableUndoRegistration {
                self.disableUndoRegistration()
            }

            action()

            if temporaryDisableUndoRegistration {
                self.enableUndoRegistration()
            }
        } else {
            action()
        }
    }
}
