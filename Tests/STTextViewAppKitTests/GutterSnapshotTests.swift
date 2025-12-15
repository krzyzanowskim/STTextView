#if os(macOS)
import XCTest
import SnapshotTesting
@testable import STTextViewAppKit

// RECORD_MODE=1 swift test --filter GutterSnapshotTests

@MainActor
final class GutterSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Disable animations for consistent snapshots
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        NSAnimationContext.endGrouping()
    }

    // MARK: - Gutter Visibility Tests

    func testTextViewWithGutterHidden() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black

        let text = """
        Line 1: First line
        Line 2: Second line
        Line 3: Third line
        Line 4: Fourth line
        Line 5: Fifth line
        """

        textView.insertText(text, replacementRange: textView.textSelection)

        // Gutter should be hidden by default
        XCTAssertFalse(textView.isGutterVisible)

        assertSnapshot(of: scrollView, as: .image)
    }

    func testTextViewWithGutterVisible() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black

        let text = """
        Line 1: First line
        Line 2: Second line
        Line 3: Third line
        Line 4: Fourth line
        Line 5: Fifth line
        """

        textView.insertText(text, replacementRange: textView.textSelection)

        // Show the gutter
        textView.isGutterVisible = true
        XCTAssertTrue(textView.isGutterVisible)

        assertSnapshot(of: scrollView, as: .image)
    }

    // MARK: - Line Count Variations

    func testGutterWithManyLines() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black


        var lines: [String] = []
        for i in 1...20 {
            lines.append("Line \(i): This is line number \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)

        // Show the gutter
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    func testGutterWithEmptyDocument() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black


        // Show gutter on empty document
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    func testGutterWithSingleLine() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black


        textView.insertText("Single line of text", replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    // MARK: - Font Variations

    func testGutterWithDifferentFontSizes() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 18, weight: .regular)
        textView.textColor = .black


        let text = """
        Line 1
        Line 2
        Line 3
        Line 4
        Line 5
        """

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    func testGutterWithSmallFont() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.textColor = .black


        let text = """
        Line 1: Small font
        Line 2: Small font
        Line 3: Small font
        Line 4: Small font
        Line 5: Small font
        """

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    // MARK: - Theme Variations

    func testGutterWithDarkTheme() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = NSColor(white: 0.1, alpha: 1.0)
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .white


        let text = """
        Line 1: Dark theme
        Line 2: With gutter
        Line 3: Line numbers
        Line 4: Should be visible
        Line 5: On dark background
        """

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    func testGutterWithCustomColors() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = NSColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = NSColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)


        let text = """
        Line 1: Custom colors
        Line 2: Sepia-like theme
        Line 3: With gutter
        Line 4: Line numbers
        Line 5: Custom styling
        """

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    // MARK: - Size Variations

    func testGutterWithSmallView() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 12)
        textView.textColor = .black


        let text = """
        Line 1
        Line 2
        Line 3
        """

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    func testGutterWithLargeView() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .black


        var lines: [String] = []
        for i in 1...15 {
            lines.append("Line \(i): This is a larger view with more content")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    // MARK: - Line Number Width Tests

    func testGutterWithDoubleDigitLineNumbers() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black


        var lines: [String] = []
        for i in 1...12 {
            lines.append("Line \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }

    func testGutterWithManyLinesScrolled() {
        let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let textView = scrollView.documentView as! STTextView
        textView.backgroundColor = .white
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black


        var lines: [String] = []
        for i in 1...30 {
            lines.append("Line \(i): This is some content for line \(i)")
        }
        let text = lines.joined(separator: "\n")

        textView.insertText(text, replacementRange: textView.textSelection)
        textView.isGutterVisible = true

        assertSnapshot(of: scrollView, as: .image)
    }
}

#endif
