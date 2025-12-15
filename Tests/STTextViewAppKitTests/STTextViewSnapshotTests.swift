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
}

#endif
