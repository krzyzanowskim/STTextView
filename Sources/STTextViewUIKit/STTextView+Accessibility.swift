//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

// MARK: - UIAccessibility

extension STTextView {

    override open var isAccessibilityElement: Bool {
        get { true }
        set { }
    }

    override open var accessibilityTraits: UIAccessibilityTraits {
        get {
            var traits: UIAccessibilityTraits = []
            if isEditable {
                // For editable text views, use staticText trait
                // The text input system handles editing-specific behaviors
                traits.insert(.staticText)
            } else {
                traits.insert(.staticText)
            }
            if !isEditable && !isSelectable {
                traits.insert(.notEnabled)
            }
            return traits
        }
        set { }
    }

    override open var accessibilityLabel: String? {
        get {
            NSLocalizedString("Text Editor", comment: "Accessibility label for text editor")
        }
        set { }
    }

    override open var accessibilityValue: String? {
        get {
            text
        }
        set {
            if let newValue {
                text = newValue
            }
        }
    }

    override open var accessibilityHint: String? {
        get {
            if isEditable {
                return NSLocalizedString("Double tap to edit", comment: "Accessibility hint for editable text")
            }
            return nil
        }
        set { }
    }

    /// The textual context of the text view, which helps VoiceOver
    /// understand how to interpret and pronounce the text content.
    ///
    /// For source code editors, use `.sourceCode` to have VoiceOver
    /// announce punctuation and special characters more explicitly.
    /// For general text editing, use `.wordProcessing`.
    ///
    /// - Note: When set to `.sourceCode`, VoiceOver will pronounce
    ///   characters like brackets, semicolons, and operators.
    override open var accessibilityTextualContext: UIAccessibilityTextualContext? {
        get {
            _accessibilityTextualContext
        }
        set {
            _accessibilityTextualContext = newValue
        }
    }

    /// Activates the text view when VoiceOver user double-taps.
    ///
    /// For editable text views, this makes the view become first responder
    /// and shows the keyboard.
    ///
    /// - Returns: `true` if the activation was handled, `false` otherwise.
    override open func accessibilityActivate() -> Bool {
        if isEditable {
            let didBecomeFirstResponder = becomeFirstResponder()
            if didBecomeFirstResponder {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: NSLocalizedString("Editing", comment: "Accessibility announcement when editing begins")
                )
            }
            return didBecomeFirstResponder
        }
        return false
    }

    /// A string that identifies the element for UI testing.
    ///
    /// Use this property to assign a unique identifier to the text view
    /// for use with UI automation testing frameworks like XCTest.
    ///
    /// Example:
    /// ```swift
    /// textView.accessibilityIdentifier = "editor.mainTextView"
    /// ```
    override open var accessibilityIdentifier: String? {
        get {
            _accessibilityIdentifier
        }
        set {
            _accessibilityIdentifier = newValue
        }
    }

    /// Indicates whether the text view responds to user interaction.
    ///
    /// Returns `true` if the text view is either editable or selectable,
    /// helping VoiceOver understand that this element can be interacted with.
    override open var accessibilityRespondsToUserInteraction: Bool {
        get {
            isEditable || isSelectable
        }
        set { }
    }

    /// Scrolls the text view content in response to VoiceOver three-finger swipe gestures.
    ///
    /// This method enables VoiceOver users to navigate through the text content
    /// using three-finger swipes. After scrolling, it announces the new position
    /// to provide context about the current location in the document.
    ///
    /// - Parameter direction: The direction to scroll.
    /// - Returns: `true` if the scroll was performed, `false` if scrolling
    ///   in that direction is not possible.
    override open func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        let viewportHeight = bounds.height
        let viewportWidth = bounds.width
        let maxOffsetY = max(0, contentSize.height - viewportHeight)
        let maxOffsetX = max(0, contentSize.width - viewportWidth)

        var newOffset = contentOffset
        var didScroll = false

        switch direction {
        case .up:
            // Scroll content down (show earlier content)
            if contentOffset.y > 0 {
                newOffset.y = max(0, contentOffset.y - viewportHeight)
                didScroll = true
            }
        case .down:
            // Scroll content up (show later content)
            if contentOffset.y < maxOffsetY {
                newOffset.y = min(maxOffsetY, contentOffset.y + viewportHeight)
                didScroll = true
            }
        case .left:
            // Scroll content right (show earlier content horizontally)
            if contentOffset.x > 0 {
                newOffset.x = max(0, contentOffset.x - viewportWidth)
                didScroll = true
            }
        case .right:
            // Scroll content left (show later content horizontally)
            if contentOffset.x < maxOffsetX {
                newOffset.x = min(maxOffsetX, contentOffset.x + viewportWidth)
                didScroll = true
            }
        case .previous, .next:
            // Handle as vertical scrolling
            if direction == .previous && contentOffset.y > 0 {
                newOffset.y = max(0, contentOffset.y - viewportHeight)
                didScroll = true
            } else if direction == .next && contentOffset.y < maxOffsetY {
                newOffset.y = min(maxOffsetY, contentOffset.y + viewportHeight)
                didScroll = true
            }
        @unknown default:
            return false
        }

        if didScroll {
            setContentOffset(newOffset, animated: true)

            // Announce new position
            let announcement = accessibilityScrollStatusMessage(for: newOffset)
            UIAccessibility.post(notification: .pageScrolled, argument: announcement)
        }

        return didScroll
    }

    /// Generates a status message describing the current scroll position.
    ///
    /// - Parameter offset: The current content offset.
    /// - Returns: A localized string describing the scroll position.
    private func accessibilityScrollStatusMessage(for offset: CGPoint) -> String {
        let totalHeight = contentSize.height
        let viewportHeight = bounds.height

        guard totalHeight > viewportHeight else {
            return NSLocalizedString("All content visible", comment: "Accessibility scroll status when all content fits")
        }

        // Calculate approximate page position
        let totalPages = Int(ceil(totalHeight / viewportHeight))
        let currentPage = Int(floor(offset.y / viewportHeight)) + 1

        let format = NSLocalizedString(
            "Page %d of %d",
            comment: "Accessibility scroll status showing current page"
        )
        return String(format: format, currentPage, totalPages)
    }
}

// MARK: - UIAccessibilityReadingContent

extension STTextView: UIAccessibilityReadingContent {

    /// Returns the line number that contains the specified point.
    /// - Parameter point: A point in the coordinate space of the accessibility element.
    /// - Returns: The line number for the specified point, or `NSNotFound` if no line exists at that point.
    public func accessibilityLineNumber(for point: CGPoint) -> Int {
        // Convert point from screen coordinates to local coordinates
        let localPoint = convert(point, from: nil)
        let adjustedPoint = CGPoint(
            x: localPoint.x - contentView.frame.origin.x,
            y: localPoint.y - contentView.frame.origin.y
        )

        // Find the text location at this point
        guard let location = textLayoutManager.caretLocation(
            interactingAt: adjustedPoint,
            inContainerAt: textLayoutManager.documentRange.location
        ) else {
            return NSNotFound
        }

        // Get line number for this location
        return lineNumber(for: location)
    }

    /// Returns the text associated with the specified line number.
    /// - Parameter lineNumber: A zero-indexed line number.
    /// - Returns: The text content of the specified line, or `nil` if the line number is invalid.
    public func accessibilityContent(forLineNumber lineNumber: Int) -> String? {
        accessibilityAttributedContent(forLineNumber: lineNumber)?.string
    }

    /// Returns the styled text associated with the specified line number.
    /// - Parameter lineNumber: A zero-indexed line number.
    /// - Returns: The attributed string content of the specified line, or `nil` if the line number is invalid.
    public func accessibilityAttributedContent(forLineNumber lineNumber: Int) -> NSAttributedString? {
        guard let lineRange = textRange(forLine: lineNumber) else {
            return nil
        }

        return textContentManager.attributedString(in: lineRange)
    }

    /// Returns the onscreen frame associated with the specified line number.
    /// - Parameter lineNumber: A zero-indexed line number.
    /// - Returns: The frame of the line in screen coordinates, or `.zero` if the line number is invalid.
    public func accessibilityFrame(forLineNumber lineNumber: Int) -> CGRect {
        guard let lineRange = textRange(forLine: lineNumber),
              let segmentFrame = textLayoutManager.textSegmentFrame(in: lineRange, type: .standard)
        else {
            return .zero
        }

        // Convert to screen coordinates
        let frameInView = segmentFrame.moved(by: contentView.frame.origin)
        return convert(frameInView, to: nil)
    }

    /// Returns the text displayed on the current page (visible viewport).
    /// - Returns: The text content currently visible in the viewport.
    public func accessibilityPageContent() -> String? {
        accessibilityAttributedPageContent()?.string
    }

    /// Returns the styled text displayed on the current page (visible viewport).
    /// - Returns: The attributed string content currently visible in the viewport.
    public func accessibilityAttributedPageContent() -> NSAttributedString? {
        guard let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return nil
        }

        return textContentManager.attributedString(in: viewportRange)
    }
}

// MARK: - Accessibility Helper Methods

extension STTextView {

    /// Returns the line number for a given text location.
    /// - Parameter location: The text location to find the line number for.
    /// - Returns: Zero-indexed line number, or 0 if the location is invalid.
    private func lineNumber(for location: NSTextLocation) -> Int {
        var lineCount = 0
        var foundLine = 0

        textContentManager.enumerateTextElements(from: textContentManager.documentRange.location) { textElement in
            guard let elementRange = textElement.elementRange else {
                return true
            }

            // Count line fragments within this element
            textLayoutManager.enumerateTextLayoutFragments(in: elementRange) { layoutFragment in
                for textLineFragment in layoutFragment.textLineFragments {
                    // Check if this line contains our location
                    if let lineRange = textLineFragment.textRange(in: layoutFragment),
                       lineRange.contains(location) || lineRange.location == location {
                        foundLine = lineCount
                        return false
                    }
                    lineCount += 1
                }
                return true
            }

            // Stop if we've passed the location
            if elementRange.endLocation > location {
                return false
            }

            return true
        }

        return foundLine
    }

    /// Returns the text range for a given line number.
    /// - Parameter lineNumber: Zero-indexed line number.
    /// - Returns: The text range for the line, or `nil` if the line number is out of bounds.
    private func textRange(forLine lineNumber: Int) -> NSTextRange? {
        var currentLine = 0
        var result: NSTextRange?

        textLayoutManager.enumerateTextLayoutFragments(
            from: textContentManager.documentRange.location,
            options: [.ensuresLayout]
        ) { layoutFragment in
            for textLineFragment in layoutFragment.textLineFragments {
                if currentLine == lineNumber {
                    result = textLineFragment.textRange(in: layoutFragment)
                    return false
                }
                currentLine += 1
            }
            return true
        }

        return result
    }
}

// MARK: - Accessibility Selection Support

extension STTextView {

    /// The range of currently selected text, expressed in terms of character offsets.
    /// Used by accessibility to report and modify selection.
    var accessibilitySelectedTextRange: NSRange {
        get {
            textSelection
        }
        set {
            setSelectedRange(newValue)
        }
    }

    /// The currently selected text.
    /// Used by accessibility to report selected content.
    var accessibilitySelectedText: String? {
        textLayoutManager.textSelectionsString()
    }

    /// The total number of characters in the text view.
    var accessibilityNumberOfCharacters: Int {
        text?.count ?? 0
    }

    /// Returns the text in the specified range.
    /// - Parameter range: The range of text to return.
    /// - Returns: The text within the specified range, or `nil` if the range is invalid.
    func accessibilityText(in range: NSRange) -> String? {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return nil
        }
        return textContentManager.attributedString(in: textRange)?.string
    }

    /// Returns the attributed text in the specified range.
    /// - Parameter range: The range of text to return.
    /// - Returns: The attributed string within the specified range, or `nil` if the range is invalid.
    func accessibilityAttributedText(in range: NSRange) -> NSAttributedString? {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return nil
        }
        return textContentManager.attributedString(in: textRange)
    }

    /// Posts an accessibility notification when the text selection changes.
    ///
    /// Note: UIKit doesn't have a direct equivalent to macOS's `selectedTextChanged` notification.
    /// We use `layoutChanged` to notify VoiceOver that the content has changed and it should
    /// re-read the current focus position.
    func postAccessibilitySelectedTextChangedNotification() {
        UIAccessibility.post(notification: .layoutChanged, argument: self)
    }

    /// Posts an accessibility announcement notification.
    /// - Parameter message: The message to announce to VoiceOver users.
    func postAccessibilityAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
