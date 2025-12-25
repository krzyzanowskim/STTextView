//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus
import STTextViewCommon

// TODO: hide UITextInput interface from STTextView public interface
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
            updateSelectedLineHighlight()
            layoutGutter()

            // Defer scroll to layout pass (like UITextView's _scrollToSelectionIfNeeded)
            needsScrollToSelection = true
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
            inputDelegate?.selectionWillChange(self)
            replaceCharacters(in: textRange, with: text, useTypingAttributes: true, allowsTypingCoalescing: true)
            inputDelegate?.selectionDidChange(self)
        }
    }

    /// Inserts the provided text and marks it to indicate that it is part of an active input session.
    /// - Parameters:
    ///   - markedText: The text to be marked.
    ///   - selectedRange: A range within markedText that indicates the current selection. This range is always relative to `markedText`.
    ///
    /// Setting marked text either replaces the existing marked text or, if none is present, inserts it in place of the current selection.
    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        let range = self.markedText?.markedRange ?? selectedRange
        let markedText = markedText ?? ""

        self.markedText = STMarkedText(
            markedText: NSAttributedString(string: markedText),
            markedRange: range,
            selectedRange: selectedRange
        )

        let selectionRange = NSRange(location: range.location + selectedRange.location, length: selectedRange.length)
        guard let selectionTextRange = NSTextRange(selectionRange, in: textContentManager) else {
            return
        }

        inputDelegate?.selectionWillChange(self)
        self.replace(
            STTextLocationRange(
                textRange: selectionTextRange
            ),
            withText: markedText
        )
        inputDelegate?.selectionDidChange(self)
    }

    public func unmarkText() {
        inputDelegate?.selectionWillChange(self)
        markedText = nil
        inputDelegate?.selectionDidChange(self)
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
        for _ in 0 ..< offset {
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
        guard let range = range as? STTextLocationRange else {
            return nil
        }

        let textRange = range.textRange

        // Return the appropriate position based on the direction
        switch direction {
        case .left, .up:
            // For left and up directions, return the start of the range
            return textRange.location.uiTextPosition
        case .right, .down:
            // For right and down directions, return the end of the range
            return textRange.endLocation.uiTextPosition
        @unknown default:
            return nil
        }
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
        guard let textLocation = position as? STTextLocation else {
            return nil
        }

        let location = textLocation.location

        // Find the other endpoint based on direction
        switch direction {
        case .left, .up:
            // For left or up, extend backwards one character if possible
            if let prevLocation = textLayoutManager.location(location, offsetBy: -1) {
                // Ensuring the start is before the end
                return NSTextRange(location: prevLocation, end: location)?.uiTextRange
            }
        case .right, .down:
            // For right or down, extend forward one character if possible
            if let nextLocation = textLayoutManager.location(location, offsetBy: 1) {
                // Ensuring the start is before the end
                return NSTextRange(location: location, end: nextLocation)?.uiTextRange
            }
        @unknown default:
            return nil
        }

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
        textLayoutManager.textSegmentFrame(in: range.nsTextRange, type: .standard)?.moved(by: contentView.frame.origin) ?? .zero
    }

    public func caretRect(for position: UITextPosition) -> CGRect {
        guard let textLocation = position as? STTextLocation else {
            return .zero
        }

        // rewrite it to lines
        var textSelectionFrames: [CGRect] = []
        textLayoutManager.enumerateTextSegments(in: NSTextRange(location: textLocation.location), type: .standard) { textSegmentRange, textSegmentFrame, _, _ in
            if let textSegmentRange {
                let documentRange = textLayoutManager.documentRange
                guard !documentRange.isEmpty else {
                    // empty document
                    textSelectionFrames.append(
                        CGRect(
                            origin: CGPoint(
                                x: textSegmentFrame.origin.x,
                                y: textSegmentFrame.origin.y
                            ),
                            size: CGSize(
                                width: textSegmentFrame.width,
                                height: typingLineHeight
                            )
                        )
                    )
                    return false
                }

                let isAtEndLocation = textSegmentRange.location == documentRange.endLocation
                guard !isAtEndLocation else {
                    // At the end of non-empty document

                    // FB15131180: extra line fragment frame is not correct hence workaround location and height at extra line
                    if let layoutFragment = textLayoutManager.extraLineTextLayoutFragment() {
                        // at least 2 lines guaranteed at this point
                        let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                        textSelectionFrames.append(
                            CGRect(
                                origin: CGPoint(
                                    x: textSegmentFrame.origin.x,
                                    y: layoutFragment.layoutFragmentFrame.origin.y + prevTextLineFragment.typographicBounds.maxY
                                ),
                                size: CGSize(
                                    width: textSegmentFrame.width,
                                    height: prevTextLineFragment.typographicBounds.height
                                )
                            )
                        )
                    } else if let prevLocation = textLayoutManager.location(textSegmentRange.endLocation, offsetBy: -1),
                              let prevTextLineFragment = textLayoutManager.textLineFragment(at: prevLocation) {
                        // Get insertion point height from the last-to-end (last) line fragment location
                        // since we're at the end location at this point.
                        textSelectionFrames.append(
                            CGRect(
                                origin: CGPoint(
                                    x: textSegmentFrame.origin.x,
                                    y: textSegmentFrame.origin.y
                                ),
                                size: CGSize(
                                    width: textSegmentFrame.width,
                                    height: prevTextLineFragment.typographicBounds.height
                                )
                            )
                        )
                    }
                    return false
                }

                // Regular where segment frame is correct
                textSelectionFrames.append(
                    textSegmentFrame
                )
            }
            return true
        }

        if let selectionFrame = textSelectionFrames.first {
            return CGRect(
                x: selectionFrame.origin.x - 1,
                y: selectionFrame.origin.y,
                width: max(2, selectionFrame.width),
                height: typingLineHeight
            ).moved(by: contentView.frame.origin).pixelAligned
        }

        return .zero
    }

    /// Returns an array of selection rects corresponding to the range of text.
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        guard let range = range as? STTextLocationRange else {
            return []
        }

        var result: [UITextSelectionRect] = []
        textLayoutManager.enumerateTextSegments(in: range.nsTextRange, type: .selection, options: .upstreamAffinity) { (textSegmentRange, textSegmentFrame, _, _) in

            var containsStart: Bool {
                if let textSegmentRange, textSegmentRange.location == range.textRange.location {
                    return true
                }
                return false
            }

            var containsEnd: Bool {
                if let textSegmentRange, textSegmentRange.endLocation == range.textRange.endLocation {
                    return true
                }
                return false
            }

            result.append(STTextSelectionRect(
                rect: textSegmentFrame.moved(by: contentView.frame.origin),
                writingDirection: baseWritingDirection(for: range.start, in: .forward),
                containsStart: containsStart,
                containsEnd: containsEnd,
                isVertical: false
            ))
            return true // keep going
        }
        return result
    }

    /* Hit testing. */

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        let eventPoint = point.moved(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        if let position = textLayoutManager.caretLocation(interactingAt: eventPoint, inContainerAt: textLayoutManager.documentRange.location)?.uiTextPosition {
            return position
        } else {
            return textLayoutManager.textSelectionNavigation.textSelections(interactingAt: eventPoint, inContainerAt: textLayoutManager.documentRange.location, anchors: [], modifiers: [], selecting: false, bounds: textLayoutManager.usageBoundsForTextContainer).first?.textRanges.first?.location.uiTextPosition
        }
    }

    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        guard let range = range as? STTextLocationRange else {
            return nil
        }

        // Convert point to account for content view offset
        let adjustedPoint = point.moved(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)

        // Attempt to find the location interacting at the point, constrained to the given range
        let candidateLocation = textLayoutManager.caretLocation(
            interactingAt: adjustedPoint,
            inContainerAt: range.textRange.location
        )

        guard let candidateLocation else {
            return nil
        }

        // If the location is within the range, return it
        if range.textRange.contains(candidateLocation) {
            return candidateLocation.uiTextPosition
        }

        // If not within range, return the closest endpoint of the range
        let startLocation = range.textRange.location
        let endLocation = range.textRange.endLocation

        // Calculate distance to start and end of range
        let distanceToStart = textContentManager.offset(from: candidateLocation, to: startLocation)
        let distanceToEnd = textContentManager.offset(from: candidateLocation, to: endLocation)

        // Return the closest endpoint
        return abs(distanceToStart) < abs(distanceToEnd)
            ? startLocation.uiTextPosition
            : endLocation.uiTextPosition
    }

    /// Returns the character or range of characters that is at a specified point in a document.
    public func characterRange(at point: CGPoint) -> UITextRange? {
        // Convert point to account for content view offset
        let adjustedPoint = point.moved(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)

        // Get location at the point
        guard let location = textLayoutManager.caretLocation(
            interactingAt: adjustedPoint,
            inContainerAt: textLayoutManager.documentRange.location
        ) else {
            return nil
        }

        // Check if we can get a text layout fragment at this location
        guard let fragment = textLayoutManager.textLayoutFragment(for: location) else {
            return nil
        }

        // Get the element range that contains this location
        guard let elementRange = fragment.textElement?.elementRange else {
            // Fallback to extending the position by one character
            return characterRange(byExtending: location.uiTextPosition, in: .right)
        }

        // Get the range for the character at the location
        if let nextLocation = textLayoutManager.location(location, offsetBy: 1),
           nextLocation <= elementRange.endLocation {
            return NSTextRange(location: location, end: nextLocation)?.uiTextRange
        } else {
            // Fallback to returning a single-position range
            return NSTextRange(location: location, end: location)?.uiTextRange
        }
    }
}
