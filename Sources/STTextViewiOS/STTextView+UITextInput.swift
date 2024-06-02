//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView: UITextInput {
    
    /* Methods for manipulating text. */
    
    public func text(in range: UITextRange) -> String? {
        // FB13810290: UITextInput.textInRange is not maked as nullable, that result in crash when used from Swift
        let range: UITextRange? = range
        guard let range else {
            return nil
        }

        return textContentManager.attributedString(in: range.nsTextRange)?.string
    }

    public func replace(_ range: UITextRange, withText text: String) {
        let textRange = range.nsTextRange

        if shouldChangeText(in: textRange, replacementString: text) {
            replaceCharacters(in: textRange, with: text, useTypingAttributes: true, allowsTypingCoalescing: true)
        }
    }

    /* Text may have a selection, either zero-length (a caret) or ranged.  Editing operations are
     * always performed on the text from this selection.  nil corresponds to no selection. */

    public var selectedTextRange: UITextRange? {
        get {
            textLayoutManager.textSelections.last?.textRanges.last?.uiTextRange
        }
        set {
            inputDelegate?.selectionWillChange(self)
            if let textRange = newValue?.nsTextRange {
                textLayoutManager.textSelections = [
                    NSTextSelection(range: textRange, affinity: .upstream, granularity: .character)
                ]
            } else {
                textLayoutManager.textSelections = []
            }
            inputDelegate?.selectionDidChange(self)
        }
    }

    /* If text can be selected, it can be marked. Marked text represents provisionally
     * inserted text that has yet to be confirmed by the user.  It requires unique visual
     * treatment in its display.  If there is any marked text, the selection, whether a
     * caret or an extended range, always resides within.
     *
     * Setting marked text either replaces the existing marked text or, if none is present,
     * inserts it from the current selection. */

    public var markedTextRange: UITextRange? {
        // assertionFailure("Not Implemented")
        return nil
    }

    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        assertionFailure("Not Implemented")
    }

    public func unmarkText() {
        assertionFailure("Not Implemented")
    }

    public var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            // TODO: implement
            nil
        }
        set(markedTextStyle) {
            // TODO: implement
        }
    }

    /* The end and beginning of the the text document. */
    
    public var beginningOfDocument: UITextPosition {
        textContentManager.documentRange.location.uiTextPosition
    }

    public var endOfDocument: UITextPosition {
        textContentManager.documentRange.endLocation.uiTextPosition
    }

    /* Methods for creating ranges and positions. */

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? STTextLocation, let toPosition = toPosition as? STTextLocation else {
            return nil
        }

        return NSTextRange(location: fromPosition.location, end: toPosition.location)?.uiTextRange
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let textLocation = position as? STTextLocation else {
            return nil
        }

        return textContentManager.location(textLocation.location, offsetBy: offset)?.uiTextPosition
    }

    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        assertionFailure("Not Implemented")
        return nil
    }
    
    /* Simple evaluation of positions */

    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard let lhs = position as? STTextLocation, let rhs = other as? STTextLocation else {
            return .orderedSame
        }

        return lhs.location.compare(rhs.location)
    }

    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard let fromTextLocation = from as? STTextLocation, let toTextLocation = toPosition as? STTextLocation else {
            return 0
        }

        return textContentManager.offset(from: fromTextLocation.location, to: toTextLocation.location)
    }

    /* A tokenizer must be provided to inform the text input system about text units of varying granularity. */

    public var tokenizer: any UITextInputTokenizer {
        UITextInputStringTokenizer(textInput: self)
    }

    /* Layout questions. */

    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        assertionFailure("Not Implemented")
        return nil
    }

//    public func characterOffset(of position: UITextPosition, within range: UITextRange) -> Int {
//        // Optional
//        assertionFailure("Not Implemented")
//        return 0
//    }

//    public func position(within range: UITextRange, atCharacterOffset offset: Int) -> UITextPosition? {
//        // Optional
//        assertionFailure("Not Implemented")
//        return nil
//    }

    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        assertionFailure("Not Implemented")
        return nil
    }

    /* Writing direction */

    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        // TODO: implement
        .natural
    }

    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        // TODO: implement
    }

    /* Geometry used to provide, for example, a correction rect. */

    public func firstRect(for range: UITextRange) -> CGRect {
        textLayoutManager.textSegmentFrame(in: range.nsTextRange, type: .selection) ?? .zero
    }

    public func caretRect(for position: UITextPosition) -> CGRect {
        guard let textLocation = position as? STTextLocation else {
            return .zero
        }

        var rect = textLayoutManager.textSegmentFrame(at: textLocation.location, type: .selection) ?? .zero
        rect.size.width = 2
        return rect
    }

    /// Returns an array of selection rects corresponding to the range of text.
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        if let rect = textLayoutManager.textSegmentFrame(in: range.nsTextRange, type: .selection) {
            return [STTextSelectionRect(
                rect: rect,
                writingDirection: .natural,
                containsStart: true,
                containsEnd: true,
                isVertical: false
            )]
        }

        return []
    }

    /* Hit testing. */

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        textLayoutManager.location(interactingAt: point, inContainerAt: textLayoutManager.documentRange.location)?.uiTextPosition
    }

    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        assertionFailure("Not Implemented")
        return nil
    }

    public func characterRange(at point: CGPoint) -> UITextRange? {
        assertionFailure("Not Implemented")
        return nil
    }
}
