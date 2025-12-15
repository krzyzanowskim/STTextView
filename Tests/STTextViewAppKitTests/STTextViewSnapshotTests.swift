#if os(macOS)
import XCTest
import SnapshotTesting
@testable import STTextViewAppKit

// RECORD_MODE=1 swift test

@MainActor
final class STTextViewSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Disable animations for consistent snapshots
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        NSAnimationContext.endGrouping()

        // Ensure consistent scroll bar behavior across different system settings
        UserDefaults.standard.set("Automatic", forKey: "AppleShowScrollBars")
    }

    override func tearDown() {
        // Restore default scroll bar setting
        UserDefaults.standard.removeObject(forKey: "AppleShowScrollBars")
        super.tearDown()
    }

    // MARK: - Basic Text Rendering

    func testEmptyTextView() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white

        assertSnapshot(of: textView, as: .image)
    }

    func testTextViewWithSimpleText() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black

        textView.insertText("Hello, World!\nThis is a test of STTextView.", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    func testTextViewWithMultilineText() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black

        let text = """
        Line 1: This is a test
        Line 2: Testing multiline text
        Line 3: With different lines
        Line 4: In STTextView
        Line 5: For snapshot testing
        """

        textView.insertText(text, replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    // MARK: - Text Selection

    func testTextViewWithSelection() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black

        textView.insertText("Hello, World!\nThis is a test.", replacementRange: textView.textSelection)

        // Select "World"
        textView.textSelection = NSRange(location: 7, length: 5)

        assertSnapshot(of: textView, as: .image)
    }

    // MARK: - Font and Styling

    func testTextViewWithCustomFont() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black

        textView.insertText("This is monospaced text\nfor testing purposes", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    func testTextViewWithDifferentFontSize() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 18)
        textView.textColor = .black

        textView.insertText("Larger font size test\nSecond line here", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    // MARK: - Editable State

    func testNonEditableTextView() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black
        textView.isEditable = false

        textView.insertText("This is non-editable text", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    // MARK: - Text Color

    func testTextViewWithCustomColor() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .blue

        textView.insertText("This text is blue", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    func testTextViewWithDarkBackground() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        textView.backgroundColor = NSColor(white: 0.1, alpha: 1.0)
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .white

        textView.insertText("White text on dark background\nLine 2", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    // MARK: - Size Variations

    func testSmallTextView() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 12)
        textView.textColor = .black

        textView.insertText("Small view", replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    func testLargeTextView() {
        let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black

        let text = """
        This is a larger text view
        With more space for content
        And multiple lines of text
        To test rendering
        In a bigger viewport
        """

        textView.insertText(text, replacementRange: textView.textSelection)

        assertSnapshot(of: textView, as: .image)
    }

    // MARK: - Scrolling

    func testScrollToLastLine() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black

        // Create 100 lines of text
        var lines: [String] = []
        for i in 1...100 {
            lines.append("Line \(i): This is line number \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)

        // Ensure layout is complete for the entire document
        textView.layout()
        let layoutManager = textView.textLayoutManager
        layoutManager.ensureLayout(for: layoutManager.documentRange)

        // Get the last line location and scroll to it
        let endLocation = textView.textContentManager.documentRange.endLocation

        // Get a location near the end of the document (last line)
        if let lastLineLocation = textView.textContentManager.location(endLocation, offsetBy: -1),
           let textRange = NSTextRange(location: lastLineLocation, end: endLocation) {
            textView.scrollToVisible(textRange, type: .standard)
        }

        assertSnapshot(of: scrollView, as: .image)
    }

    /// Test inserting text at the end while viewing the end - canvas should not shrink
    func testInsertAtEndWhileViewingEnd() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black

        // Create 100 lines of text
        var lines: [String] = []
        for i in 1...100 {
            lines.append("Line \(i): This is line number \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.layout()

        let layoutManager = textView.textLayoutManager
        layoutManager.ensureLayout(for: layoutManager.documentRange)

        // Scroll to the end and position cursor there
        let endLocation = textView.textContentManager.documentRange.endLocation
        if let lastCharLocation = textView.textContentManager.location(endLocation, offsetBy: -1),
           let textRange = NSTextRange(location: lastCharLocation, end: endLocation) {
            textView.scrollToVisible(textRange, type: .standard)
        }
        let endOffset = layoutManager.offset(from: textView.textContentManager.documentRange.location, to: endLocation)
        textView.setSelectedRange(NSRange(location: endOffset, length: 0))
        textView.layout()

        let frameBefore = textView.frame
        let visibleRectBefore = textView.visibleRect
        print("Before insert - frame: \(frameBefore), visibleRect: \(visibleRectBefore)")

        // Insert new line at the end
        textView.insertText("\nLine 101: New line at end", replacementRange: textView.textSelection)
        textView.layout()

        let frameAfter = textView.frame
        let visibleRectAfter = textView.visibleRect
        print("After insert - frame: \(frameAfter), visibleRect: \(visibleRectAfter)")

        // Frame should grow or stay same, NOT shrink
        XCTAssertGreaterThanOrEqual(frameAfter.height, frameBefore.height - 50, "Frame should not shrink significantly after inserting text")

        // Should be able to scroll to see line 101
        let newEndLocation = textView.textContentManager.documentRange.endLocation
        if let lastLineLocation = textView.textContentManager.location(newEndLocation, offsetBy: -1),
           let textRange = NSTextRange(location: lastLineLocation, end: newEndLocation) {
            textView.scrollToVisible(textRange, type: .standard)
        }
        textView.layout()

        let visibleRectFinal = textView.visibleRect
        print("After scrollToVisible - visibleRect: \(visibleRectFinal)")

        // The last line should be visible (frame should extend to cover it)
        let lastLineFrame = layoutManager.textSegmentFrame(at: textView.textContentManager.documentRange.endLocation, type: .standard)
        print("Last line frame: \(String(describing: lastLineFrame))")

        if let lastLineFrame = lastLineFrame {
            XCTAssertLessThanOrEqual(lastLineFrame.maxY, frameAfter.height + 50, "Last line should be within frame bounds")
        }
    }

    /// Test resetting text while scrolled to the end - content should not be cut off
    func testResetTextWhileScrolledToEnd() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black

        // Create 100 lines of text
        var lines: [String] = []
        for i in 1...100 {
            lines.append("Line \(i): This is line number \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.layout()

        let layoutManager = textView.textLayoutManager
        layoutManager.ensureLayout(for: layoutManager.documentRange)

        // Scroll to the end
        let endLocation = textView.textContentManager.documentRange.endLocation
        if let lastCharLocation = textView.textContentManager.location(endLocation, offsetBy: -1),
           let textRange = NSTextRange(location: lastCharLocation, end: endLocation) {
            textView.scrollToVisible(textRange, type: .standard)
        }
        textView.layout()

        let frameBefore = textView.frame
        let visibleRectBeforeReset = textView.visibleRect
        print("Frame before reset: \(frameBefore)")
        print("Visible rect before reset: \(visibleRectBeforeReset)")

        // Reset the text using the text property (like the real app would)
        textView.text = text
        textView.layout()
        layoutManager.ensureLayout(for: layoutManager.documentRange)

        let frameAfter = textView.frame
        let visibleRectAfterReset = textView.visibleRect
        print("Frame after reset: \(frameAfter)")
        print("Visible rect after reset: \(visibleRectAfterReset)")

        // Frame should be approximately the same size (content is the same)
        XCTAssertGreaterThan(frameAfter.height, frameBefore.height - 100, "Frame should not shrink significantly after resetting text")

        // Should be able to scroll to see all content
        let newEndLocation = textView.textContentManager.documentRange.endLocation
        if let lastCharLocation = textView.textContentManager.location(newEndLocation, offsetBy: -1),
           let textRange = NSTextRange(location: lastCharLocation, end: newEndLocation) {
            textView.scrollToVisible(textRange, type: .standard)
        }
        textView.layout()

        // Verify we can see the last line (line 100)
        let lastLineFrame = layoutManager.textSegmentFrame(at: textView.textContentManager.documentRange.endLocation, type: .standard)
        print("Last line frame: \(String(describing: lastLineFrame))")

        if let lastLineFrame = lastLineFrame {
            XCTAssertLessThanOrEqual(lastLineFrame.maxY, textView.frame.height, "Last line should be within frame bounds after reset")
        }
    }

    /// Test typing at the end of a long document - view should not jump away
    func testTypeAtEndOfLongDocument() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black

        // Create 100 lines of text
        var lines: [String] = []
        for i in 1...100 {
            lines.append("Line \(i): This is line number \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.layout()

        let layoutManager = textView.textLayoutManager
        layoutManager.ensureLayout(for: layoutManager.documentRange)

        // Scroll to end and position cursor there
        let endLocation = textView.textContentManager.documentRange.endLocation
        if let lastCharLocation = textView.textContentManager.location(endLocation, offsetBy: -1),
           let textRange = NSTextRange(location: lastCharLocation, end: endLocation) {
            textView.scrollToVisible(textRange, type: .standard)
        }
        let endOffset = layoutManager.offset(from: textView.textContentManager.documentRange.location, to: endLocation)
        textView.setSelectedRange(NSRange(location: endOffset, length: 0))
        textView.layout()

        let visibleRectBefore = textView.visibleRect
        let frameBefore = textView.frame

        // Type multiple characters at the end (simulating user typing)
        textView.insertText("a", replacementRange: textView.textSelection)
        textView.layout()
        textView.insertText("b", replacementRange: textView.textSelection)
        textView.layout()
        textView.insertText("c", replacementRange: textView.textSelection)
        textView.layout()
        textView.insertText("\n", replacementRange: textView.textSelection)
        textView.layout()

        let visibleRectAfter = textView.visibleRect
        let frameAfter = textView.frame

        // Frame should grow to accommodate new content
        XCTAssertGreaterThanOrEqual(frameAfter.height, frameBefore.height, "Frame should grow when typing at end")

        // View should stay near the end, not jump away
        // The visible rect Y should be close to the end of the frame
        let distanceFromEnd = frameAfter.height - visibleRectAfter.maxY
        XCTAssertLessThan(distanceFromEnd, 50.0, "View should stay at the end when typing there, not jump away")

        // Verify we can still see the last line
        let newEndLocation = textView.textContentManager.documentRange.endLocation
        if let selectionFrame = layoutManager.textSegmentFrame(at: newEndLocation, type: .standard) {
            XCTAssertLessThanOrEqual(selectionFrame.maxY, frameAfter.height, "Last line should be within frame bounds")
        }
    }

    /// Test typing at cursor position in middle of long document
    func testTypeNewLineAtCursorInMiddle() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black

        // Create 100 lines of text
        var lines: [String] = []
        for i in 1...100 {
            lines.append("Line \(i): This is line number \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.layout()

        // Scroll to middle and position cursor there
        let layoutManager = textView.textLayoutManager
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        let startLocation = textView.textContentManager.documentRange.location
        if let middleLocation = textView.textContentManager.location(startLocation, offsetBy: 1000),
           let textRange = NSTextRange(location: middleLocation, end: middleLocation) {
            // First scroll to the middle
            textView.scrollToVisible(textRange, type: .standard)
            // Then set the selection there
            let middleOffset = layoutManager.offset(from: startLocation, to: middleLocation)
            textView.setSelectedRange(NSRange(location: middleOffset, length: 0))
        }
        textView.layout()

        let visibleRectBefore = textView.visibleRect
        print("Before typing - visible rect: \(visibleRectBefore)")

        // Type a newline at current cursor position (simulating user pressing Enter)
        textView.insertText("\n", replacementRange: textView.textSelection)
        textView.layout()

        let visibleRectAfter = textView.visibleRect
        print("After typing - visible rect: \(visibleRectAfter)")

        let scrollDelta = abs(visibleRectAfter.origin.y - visibleRectBefore.origin.y)
        print("Scroll delta: \(scrollDelta)")

        // Cursor should stay visible, small scroll is OK but not large jumps
        XCTAssertLessThan(scrollDelta, 100.0, "View should not jump significantly when typing at cursor")
    }
}

#endif
