//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension STTextView: UITextInput {

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

    public var selectedTextRange: UITextRange? {
        get {
            textLayoutManager.textSelections.last?.textRanges.last?.uiTextRange
        }
        set {
            if let textRange = newValue?.nsTextRange {
                textLayoutManager.textSelections = [
                    NSTextSelection(range: textRange, affinity: .downstream, granularity: .character)
                ]
            } else {
                textLayoutManager.textSelections = []
            }
        }
    }

    public var markedTextRange: UITextRange? {
        // assertionFailure("Not Implemented")
        return nil
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

    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        assertionFailure("Not Implemented")
    }

    public func unmarkText() {
        assertionFailure("Not Implemented")
    }

    public var beginningOfDocument: UITextPosition {
        textContentManager.documentRange.location.uiTextPosition
    }

    public var endOfDocument: UITextPosition {
        textContentManager.documentRange.endLocation.uiTextPosition
    }

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? UITextLocation, let toPosition = toPosition as? UITextLocation else {
            return nil
        }

        return NSTextRange(location: fromPosition.location, end: toPosition.location)?.uiTextRange
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let textLocation = position as? UITextLocation else {
            return nil
        }

        return textContentManager.location(textLocation.location, offsetBy: offset)?.uiTextPosition
    }

    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        assertionFailure("Not Implemented")
        return nil
    }

    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard let lhs = position as? UITextLocation, let rhs = other as? UITextLocation else {
            return .orderedSame
        }

        return lhs.location.compare(rhs.location)
    }

    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard let fromTextLocation = from as? UITextLocation, let toTextLocation = toPosition as? UITextLocation else {
            return 0
        }

        return textContentManager.offset(from: fromTextLocation.location, to: toTextLocation.location)
    }

    public var tokenizer: any UITextInputTokenizer {
        UITextInputStringTokenizer(textInput: self)
    }

    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        assertionFailure("Not Implemented")
        return nil
    }

    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        assertionFailure("Not Implemented")
        return nil
    }

    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        // TODO: implement
        .natural
    }

    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        // TODO: implement
    }

    public func firstRect(for range: UITextRange) -> CGRect {
        // TODO: implement
        .zero
    }

    public func caretRect(for position: UITextPosition) -> CGRect {
        // TODO: implement
        .zero
    }

    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // TODO: implement
        []
    }

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        // TODO: implement
        nil
    }

    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        // TODO: implement
        nil
    }

    public func characterRange(at point: CGPoint) -> UITextRange? {
        // TODO: implement
        nil
    }
}
