//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension STTextView: UITextInput {
    public func text(in range: UITextRange) -> String? {
        // TODO: implement
        nil
    }

    public func replace(_ range: UITextRange, withText text: String) {
        // TODO: implement
    }

    public var selectedTextRange: UITextRange? {
        get {
            // TODO: implement
            nil
        }
        set(selectedTextRange) {
            // TODO: implement
        }
    }

    public var markedTextRange: UITextRange? {
        // TODO: implement
        nil
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
        // TODO: implement
    }

    public func unmarkText() {
        // TODO: implement
    }

    public var beginningOfDocument: UITextPosition {
        // TODO: implement
        .init()
    }

    public var endOfDocument: UITextPosition {
        // TODO: implement
        .init()
    }

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        // TODO: implement
        nil
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        // TODO: implement
        nil
    }

    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        // TODO: implement
        nil
    }

    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        // TODO: implement
        .orderedSame
    }

    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        // TODO: implement
        0
    }

    public var inputDelegate: (any UITextInputDelegate)? {
        get {
            // TODO: implement
            nil
        }
        set(inputDelegate) {
            // TODO: implement
        }
    }

    public var tokenizer: any UITextInputTokenizer {
        fatalError()
    }

    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        // TODO: implement
        nil
    }

    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        nil
        // TODO: implement
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
