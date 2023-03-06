//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

// The default implementation of the NSView method inputContext manages
// an NSTextInputContext instance automatically if the view subclass conforms
// to the NSTextInputClient protocol.
extension STTextView: NSTextInputClient {

    open override func keyDown(with event: NSEvent) {
        processingKeyEvent = true
        defer {
            processingKeyEvent = false
        }

        NSCursor.setHiddenUntilMouseMoves(true)

        // ^Space -> complete:
        if event.modifierFlags.contains(.control) && event.charactersIgnoringModifiers == " " {
            doCommand(by: #selector(NSStandardKeyBindingResponding.complete(_:)))
            return
        }

        interpretKeyEvents([event])
    }

    /// Called by the input manager to set text which might be combined with further input to form the final text (e.g. composition of ^ and a to â).
    /// The receiver inserts string replacing the content specified by replacementRange.
    /// string can be either an NSString or NSAttributedString instance.
    /// selectedRange specifies the selection inside the string being inserted;
    /// hence, the location is relative to the beginning of string.
    /// When string is an NSString, the receiver is expected to render the marked text with distinguishing appearance (i.e. NSTextView renders with -markedTextAttributes).
    public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        // print("setMarkedText")
    }

    /// The receiver unmarks the marked text. If no marked text, the invocation of this method has no effect.
    public func unmarkText() {
        // print("unmarkText")

    }

    public func selectedRange() -> NSRange {
        if let selectionTextRange = textLayoutManager.textSelections.first?.textRanges.first {
            return NSRange(selectionTextRange, in: textContentStorage)
        }

        return NSRange.notFound
    }

    /// Returns the marked range. Returns {NSNotFound, 0} if no marked range.
    public func markedRange() -> NSRange {
        NSRange.notFound
    }

    /// Returns whether or not the receiver has marked text.
    public func hasMarkedText() -> Bool {
        false
    }

    public func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        textContentStorage.attributedString?.attributedSubstring(from: range)
    }

    public func attributedString() -> NSAttributedString {
        textContentStorage.attributedString ?? NSAttributedString()
    }

    public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        [.font, .foregroundColor, .glyphInfo, .kern, .ligature, .link, .markedClauseSegment, .obliqueness, .paragraphStyle, .shadow, .spellingState,  .strikethroughColor, .strikethroughStyle, .strokeColor, .strokeWidth, .superscript, .textAlternatives, .textEffect, .toolTip, .underlineColor, .underlineStyle, .verticalGlyphForm, .writingDirection]
    }

    public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        guard let textRange = NSTextRange(range, in: textContentStorage) else {
            return .zero
        }

        var rect: NSRect = .zero
        textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: .rangeNotRequired) { _, textSegmentFrame, baselinePosition, textContainer in
            rect = window!.convertToScreen(convert(textSegmentFrame, to: nil))
            return false
        }

        return rect
    }

    public func characterIndex(for point: NSPoint) -> Int {
        guard let textLayoutFragment = textLayoutManager.textLayoutFragment(for: point) else {
            return NSNotFound
        }

        return textLayoutManager.offset(
            from: textLayoutManager.documentRange.location, to: textLayoutFragment.rangeInElement.location
        )
    }

    open func insertText(_ string: Any, replacementRange: NSRange) {
        guard isEditable else { return }

        let replacementTextRange = NSTextRange(replacementRange, in: textContentStorage)
        var textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
        if let replacementTextRange {
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
