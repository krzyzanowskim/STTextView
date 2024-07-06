//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView: UITextInput {

    /// Text may have a selection, either zero-length (a caret) or ranged.  Editing operations are
    /// always performed on the text from this selection.  nil corresponds to no selection.
    public var selectedTextRange: UITextRange? {
        get {
            guard let textSelection = textLayoutManager.textSelections.last else {
                return nil
            }

            return textSelection.textRanges.last?.uiTextRange
        }
        set {
            inputDelegate?.selectionWillChange(self)
            if let textRange = newValue?.nsTextRange {
                textLayoutManager.textSelections = [
                    NSTextSelection(range: textRange, affinity: .downstream, granularity: .character)
                ]
                updateTypingAttributes(at: textRange.location)
            } else {
                textLayoutManager.textSelections = []
            }

            inputDelegate?.selectionDidChange(self)

            if let newValue, var rect = self.selectionRects(for: newValue).last?.rect {
                rect.size.height = max(rect.size.height, contentScaleFactor)
                rect.size.width = max(rect.size.width, contentScaleFactor)
                scrollRectToVisible(rect, animated: true)
            }
        }
    }

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

    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        assertionFailure("Not Implemented")
    }

    public func unmarkText() {
        assertionFailure("Not Implemented")
    }

    /* The end and beginning of the the text document. */

    public var beginningOfDocument: UITextPosition {
        textLayoutManager.documentRange.location.uiTextPosition
    }

    public var endOfDocument: UITextPosition {
        textLayoutManager.documentRange.endLocation.uiTextPosition
    }

    /* Methods for creating ranges and positions. */

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? STTextLocation, let toPosition = toPosition as? STTextLocation else {
            return nil
        }

        if fromPosition.location < toPosition.location {
            return NSTextRange(location: fromPosition.location, end: toPosition.location)?.uiTextRange
        } else {
            return NSTextRange(location: toPosition.location, end: fromPosition.location)?.uiTextRange
        }
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let textLocation = position as? STTextLocation else {
            return nil
        }

        return textLayoutManager.location(textLocation.location, offsetBy: offset)?.uiTextPosition
    }

    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        guard let position = position as? STTextLocation else {
            return nil
        }

        let positionSelection = NSTextSelection(position.location, affinity: .downstream)
        var destination: NSTextSelection? = positionSelection
        for _ in 0..<offset {
            destination = textLayoutManager.textSelectionNavigation.destinationSelection(
                for: destination ?? positionSelection,
                direction: direction.textSelectionNavigationDirection,
                destination: .character,
                extending: false,
                confined: false
            )
        }

        return destination?.textRanges.first?.location.uiTextPosition
    }
    
    /* Simple evaluation of positions */

    /// Returns how one text position compares to another text position.
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard let lhs = position as? STTextLocation, let rhs = other as? STTextLocation else {
            return .orderedSame
        }

        return lhs.location.compare(rhs.location)
    }

    /// Returns the number of UTF-16 characters between one text position and another text position.
    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard let fromTextLocation = from as? STTextLocation, let toTextLocation = toPosition as? STTextLocation else {
            return 0
        }

        return textContentManager.offset(from: fromTextLocation.location, to: toTextLocation.location)
    }

    /* Layout questions. */

    /// Returns the text position that is at the farthest extent in a specified layout direction within a range of text.
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
        guard let textLocation = position as? STTextLocation else {
            return .natural
        }

        let writingDirection = textLayoutManager.baseWritingDirection(at: textLocation.location)
        switch writingDirection {
        case .leftToRight:
            return .leftToRight
        case .rightToLeft:
            return .rightToLeft
        @unknown default:
            return .natural
        }
    }

    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        textContentManager.performEditingTransaction {
            let attrs: [NSAttributedString.Key: Any] = [:]
            (textContentManager as? NSTextContentStorage)?.textStorage?.setAttributes(attrs, range: NSRange(range.nsTextRange, in: textContentManager))
        }
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
        rect.origin.x -= 1
        rect.size.width = 2
        return rect
    }

    /// Returns an array of selection rects corresponding to the range of text.
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        var result: [UITextSelectionRect] = []
        textLayoutManager.enumerateTextSegments(in: range.nsTextRange, type: .selection, options: .rangeNotRequired) { (_, textSegmentFrame, _, _)in
            result.append(STTextSelectionRect(
                rect: textSegmentFrame,
                writingDirection: baseWritingDirection(for: range.start, in: .forward),
                containsStart: false,
                containsEnd: false,
                isVertical: false
            ))
            return true // keep going
        }
        return result
    }

    /* Hit testing. */

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        textLayoutManager.location(interactingAt: point, inContainerAt: textLayoutManager.documentRange.location)?.uiTextPosition
    }

    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        assertionFailure("Not Implemented")
        return nil
    }

    /// Returns the character or range of characters that is at a specified point in a document.
    public func characterRange(at point: CGPoint) -> UITextRange? {
        assertionFailure("Not Implemented")
        
        return nil
    }
}
