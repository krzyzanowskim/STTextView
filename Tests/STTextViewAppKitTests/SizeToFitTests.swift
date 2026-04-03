#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    final class SizeToFitTests: XCTestCase {

        @MainActor
        func testSizeToFitHeightFitsContent() {
            let textView = STTextView()
            textView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false

            textView.attributedText = NSAttributedString(string: "Line 1\nLine 2\nLine 3")
            textView.sizeToFit()

            // 3 lines of text at ~16pt each should be ~48pt
            XCTAssertGreaterThan(textView.frame.height, 40)
            XCTAssertLessThan(textView.frame.height, 60)
        }

        @MainActor
        func testCompareUsageBoundsForTextContainer() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Line 1\nLine 2\nLine 3\n"
            nsTextView.textLayoutManager!.ensureLayout(for: .null)

            let stTextView = STTextView()
            stTextView.frame = nsTextView.frame
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = nsTextView.isVerticallyResizable
            stTextView.isHorizontallyResizable = nsTextView.isHorizontallyResizable
            stTextView.setString(nsTextView.string)
            stTextView.textLayoutManager.ensureLayout(for: .null)

            XCTAssertEqual(
                nsTextView.textLayoutManager!.usageBoundsForTextContainer,
                stTextView.textLayoutManager.usageBoundsForTextContainer
            )
        }

        @MainActor
        func testCompareSizeToFit() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Line 1\nLine 2\nLine 3\n"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = nsTextView.isVerticallyResizable
            stTextView.isHorizontallyResizable = nsTextView.isHorizontallyResizable
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitExtraLineFragment() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Line 1\nLine 2\nLine 3\n\n"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = nsTextView.isVerticallyResizable
            stTextView.isHorizontallyResizable = nsTextView.isHorizontallyResizable
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitEmpty() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = ""
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = nsTextView.isVerticallyResizable
            stTextView.isHorizontallyResizable = nsTextView.isHorizontallyResizable
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Single Line Tests

        @MainActor
        func testCompareSizeToFitSingleLine() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Hello World"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitSingleLineWithTrailingNewline() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Hello World\n"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Resizable Dimension Tests

        @MainActor
        func testCompareSizeToFitVerticalOnlyResizable() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = false
            nsTextView.string = "Line 1\nLine 2\nLine 3"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame.height, stTextView.frame.height, "Height should match when only vertically resizable")
            XCTAssertEqual(100, stTextView.frame.width, "Width should remain unchanged when not horizontally resizable")
        }

        @MainActor
        func testCompareSizeToFitHorizontalOnlyResizable() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = false
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Hello World"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = false
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame.width, stTextView.frame.width, "Width should match when only horizontally resizable")
            XCTAssertEqual(100, stTextView.frame.height, "Height should remain unchanged when not vertically resizable")
        }

        @MainActor
        func testCompareSizeToFitNeitherResizable() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.defaultParagraphStyle = .default
            stTextView.isVerticallyResizable = false
            stTextView.isHorizontallyResizable = false
            stTextView.setString("Line 1\nLine 2\nLine 3")
            stTextView.sizeToFit()

            XCTAssertEqual(100, stTextView.frame.width, "Width should remain unchanged when not resizable")
            XCTAssertEqual(100, stTextView.frame.height, "Height should remain unchanged when not resizable")
        }

        // MARK: - Whitespace and Special Characters

        @MainActor
        func testCompareSizeToFitOnlyNewline() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "\n"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitMultipleEmptyLines() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "\n\n\n\n\n"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitWhitespaceOnly() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "     "
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitTabs() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Col1\tCol2\tCol3"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Unicode and Emoji

        @MainActor
        func testCompareSizeToFitEmoji() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Hello 👋🌍🎉"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitUnicode() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "日本語テキスト\n中文文本\nПривет мир"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Font Size Tests

        @MainActor
        func testCompareSizeToFitLargeFont() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            nsTextView.font = NSFont.systemFont(ofSize: 36)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Large Text\nSecond Line"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitSmallFont() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.systemFont(ofSize: 9)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Small text on multiple\nlines of content\nthird line"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Long Content Tests

        @MainActor
        func testSizeToFitLongSingleLineExpandsHorizontally() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.defaultParagraphStyle = .default
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString("This is a very long line of text that should extend beyond the initial frame width significantly")
            stTextView.sizeToFit()

            XCTAssertGreaterThan(stTextView.frame.width, 100, "Width should expand to fit text")
            XCTAssertLessThan(stTextView.frame.height, 30, "Height should be single line, not wrapped")
        }

        @MainActor
        func testCompareSizeToFitManyLines() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = (1 ... 20).map { "Line \($0)" }.joined(separator: "\n")
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Mixed Content

        @MainActor
        func testCompareSizeToFitMixedLineEndings() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Line1\nLine2\r\nLine3\rLine4"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        @MainActor
        func testCompareSizeToFitVaryingLineLengths() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = true
            nsTextView.string = "Short\nThis is a much longer line of text\nMedium length\nX"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame, stTextView.frame)
        }

        // MARK: - Wrap / No-Wrap Tests

        @MainActor
        func testWrapModeTextContainerWidth() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView.setString("This is a long line that should wrap within the container width")
            stTextView.sizeToFit()

            XCTAssertLessThanOrEqual(stTextView.textContainer.size.width, stTextView.frame.width)
        }

        @MainActor
        func testNoWrapModeTextContainerWidth() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString("This is a long line that should NOT wrap")
            stTextView.sizeToFit()

            XCTAssertGreaterThan(stTextView.textContainer.size.width, 1000)
        }

        @MainActor
        func testCompareWrapModeContainerSize() {
            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = false
            nsTextView.string = "This is text that will wrap"
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView.setString(nsTextView.string)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.textContainer!.size.width, stTextView.textContainer.size.width, accuracy: 1.0)
        }

        @MainActor
        func testCompareNoWrapModeContainerSize() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString("This is text that will NOT wrap")
            stTextView.sizeToFit()

            XCTAssertGreaterThan(stTextView.textContainer.size.width, 1000)
        }

        @MainActor
        func testToggleWrapToNoWrap() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView.setString("This is a long line of text for testing wrap toggle behavior")
            stTextView.layoutSubtreeIfNeeded()

            let wrapContainerWidth = stTextView.textContainer.size.width
            XCTAssertLessThanOrEqual(wrapContainerWidth, 200)

            stTextView.isHorizontallyResizable = true
            stTextView.layoutSubtreeIfNeeded()

            let noWrapContainerWidth = stTextView.textContainer.size.width

            XCTAssertGreaterThan(noWrapContainerWidth, wrapContainerWidth)
            XCTAssertGreaterThan(noWrapContainerWidth, 1000)
        }

        @MainActor
        func testToggleNoWrapToWrap() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString("This is a long line of text for testing wrap toggle behavior")
            stTextView.layoutSubtreeIfNeeded()

            let noWrapContainerWidth = stTextView.textContainer.size.width
            XCTAssertGreaterThan(noWrapContainerWidth, 1000)

            stTextView.isHorizontallyResizable = false
            stTextView.layoutSubtreeIfNeeded()

            let wrapContainerWidth = stTextView.textContainer.size.width

            XCTAssertLessThan(wrapContainerWidth, noWrapContainerWidth)
            XCTAssertLessThanOrEqual(wrapContainerWidth, stTextView.frame.width)
        }

        @MainActor
        func testToggleWrapModes() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.defaultParagraphStyle = .default
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView.setString("Test text for wrap mode comparison that is long enough to wrap")
            stTextView.layoutSubtreeIfNeeded()

            let wrapModeContainerWidth = stTextView.textContainer.size.width

            XCTAssertLessThanOrEqual(wrapModeContainerWidth, 200)

            stTextView.isHorizontallyResizable = true
            stTextView.layoutSubtreeIfNeeded()

            let noWrapModeContainerWidth = stTextView.textContainer.size.width

            XCTAssertGreaterThan(noWrapModeContainerWidth, wrapModeContainerWidth)
        }

        @MainActor
        func testWrapModeLongLineWraps() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView
                .setString("This is a very long line of text that definitely should wrap to multiple lines when the container is narrow")
            stTextView.sizeToFit()

            XCTAssertEqual(stTextView.frame.width, 100, accuracy: 1.0)
            XCTAssertGreaterThan(stTextView.frame.height, 50)
        }

        @MainActor
        func testNoWrapModeLongLineExpands() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString("This is a very long line of text that should expand horizontally without wrapping")
            stTextView.sizeToFit()

            XCTAssertGreaterThan(stTextView.frame.width, 100)
            XCTAssertLessThan(stTextView.frame.height, 30)
        }

        @MainActor
        func testCompareWrapModeLongLine() {
            let longLine = "This is a very long line of text that will definitely need to wrap when the container width is constrained to a narrow value like two hundred pixels"

            let nsTextView = NSTextView(usingTextLayoutManager: true)
            nsTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            nsTextView.font = NSFont.preferredFont(forTextStyle: .body)
            nsTextView.defaultParagraphStyle = .default
            nsTextView.isVerticallyResizable = true
            nsTextView.isHorizontallyResizable = false
            nsTextView.string = longLine
            nsTextView.sizeToFit()

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = nsTextView.font!
            stTextView.defaultParagraphStyle = nsTextView.defaultParagraphStyle!
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = false
            stTextView.setString(longLine)
            stTextView.sizeToFit()

            XCTAssertEqual(nsTextView.frame.width, stTextView.frame.width, accuracy: 1.0)
            XCTAssertEqual(nsTextView.frame.height, stTextView.frame.height, accuracy: 5.0)
        }

        @MainActor
        func testNoWrapModeLongLineSingleLine() {
            let longLine = "This is a very long line of text that should NOT wrap in no-wrap mode"

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.preferredFont(forTextStyle: .body)
            stTextView.defaultParagraphStyle = .default
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.setString(longLine)
            stTextView.sizeToFit()

            XCTAssertGreaterThan(stTextView.frame.width, 200)
            XCTAssertLessThan(stTextView.frame.height, 30)
        }

        // MARK: - Gutter (Line Numbers) Tests

        @MainActor
        func testSizeToFitIncludesGutterWidth() {
            // Test that sizeToFit() includes gutter width when line numbers are shown
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = false
            stTextView.setString("This is a long line of text for testing gutter width")
            stTextView.sizeToFit()

            let frameWidthWithoutGutter = stTextView.frame.width

            // Now enable line numbers
            stTextView.showsLineNumbers = true
            stTextView.sizeToFit()

            let frameWidthWithGutter = stTextView.frame.width
            let gutterWidth = stTextView.gutterView?.frame.width ?? 0

            XCTAssertGreaterThan(gutterWidth, 0, "Gutter should have non-zero width when line numbers are shown")
            XCTAssertGreaterThan(frameWidthWithGutter, frameWidthWithoutGutter, "Frame should be wider with gutter")
            XCTAssertEqual(frameWidthWithGutter, frameWidthWithoutGutter + gutterWidth, accuracy: 1.0, "Frame width should include gutter width")
        }

        @MainActor
        func testSizeToFitMatchesIntrinsicContentSizeWithGutter() {
            // Test that sizeToFit() produces a frame consistent with intrinsicContentSize
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = true
            stTextView.setString("This is a long line of text that should expand horizontally")
            stTextView.sizeToFit()

            let intrinsicWidth = stTextView.intrinsicContentSize.width
            let frameWidth = stTextView.frame.width

            XCTAssertEqual(frameWidth, intrinsicWidth, accuracy: 1.0, "sizeToFit() frame width should match intrinsicContentSize width")
        }

        @MainActor
        func testSizeToFitWithGutterAndLongContent() {
            // Test horizontal scrolling scenario: long content with line numbers enabled
            let longLine = String(repeating: "x", count: 200) // Very long line
            
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = true
            stTextView.setString(longLine)
            stTextView.sizeToFit()

            let gutterWidth = stTextView.gutterView?.frame.width ?? 0
            let textWidth = stTextView.textLayoutManager.usageBoundsForTextContainer.width

            // Frame should be at least text width + gutter width
            XCTAssertGreaterThanOrEqual(stTextView.frame.width, textWidth + gutterWidth - 1, "Frame should include both text content and gutter")
        }

        // MARK: - Custom Gutter Tests

        @MainActor
        func testSizeToFitIncludesCustomGutterWidth() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = false
            stTextView.setString("Testing custom gutter width sizing")
            stTextView.sizeToFit()

            let frameWidthWithoutGutter = stTextView.frame.width

            // Set custom gutter width (without built-in line numbers)
            stTextView.customGutterWidth = 64
            stTextView.sizeToFit()

            let frameWidthWithCustomGutter = stTextView.frame.width

            XCTAssertGreaterThan(frameWidthWithCustomGutter, frameWidthWithoutGutter, "Frame should be wider with custom gutter")
            XCTAssertEqual(frameWidthWithCustomGutter, frameWidthWithoutGutter + 64, accuracy: 1.0, "Frame width should include custom gutter width")
        }

        @MainActor
        func testIntrinsicContentSizeIncludesCustomGutterWidth() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = false
            stTextView.setString("Testing intrinsic content size with custom gutter")
            stTextView.sizeToFit()

            let intrinsicWidthWithoutGutter = stTextView.intrinsicContentSize.width

            stTextView.customGutterWidth = 80
            stTextView.sizeToFit()

            let intrinsicWidthWithCustomGutter = stTextView.intrinsicContentSize.width

            XCTAssertGreaterThan(intrinsicWidthWithCustomGutter, intrinsicWidthWithoutGutter, "Intrinsic width should include custom gutter")
            XCTAssertEqual(intrinsicWidthWithCustomGutter, intrinsicWidthWithoutGutter + 80, accuracy: 1.0, "Intrinsic width should grow by custom gutter width")
        }

        @MainActor
        func testSizeToFitMatchesIntrinsicContentSizeWithCustomGutter() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = false
            stTextView.customGutterWidth = 64
            stTextView.setString("Consistency between sizeToFit and intrinsicContentSize")
            stTextView.sizeToFit()

            let intrinsicWidth = stTextView.intrinsicContentSize.width
            let frameWidth = stTextView.frame.width

            XCTAssertEqual(frameWidth, intrinsicWidth, accuracy: 1.0, "sizeToFit() frame width should match intrinsicContentSize width with custom gutter")
        }

        @MainActor
        func testCustomGutterWidthResetRemovesOffset() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = false
            stTextView.setString("Testing gutter removal")
            stTextView.sizeToFit()

            let frameWidthWithoutGutter = stTextView.frame.width

            // Add custom gutter
            stTextView.customGutterWidth = 64
            stTextView.sizeToFit()
            XCTAssertGreaterThan(stTextView.frame.width, frameWidthWithoutGutter)

            // Remove custom gutter
            stTextView.customGutterWidth = 0
            stTextView.sizeToFit()

            XCTAssertEqual(stTextView.frame.width, frameWidthWithoutGutter, accuracy: 1.0, "Frame should return to original width after removing custom gutter")
        }

        @MainActor
        func testCustomGutterWithLongContent() {
            let longLine = String(repeating: "x", count: 200)

            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.isVerticallyResizable = true
            stTextView.isHorizontallyResizable = true
            stTextView.showsLineNumbers = false
            stTextView.customGutterWidth = 64
            stTextView.setString(longLine)
            stTextView.sizeToFit()

            let textWidth = stTextView.textLayoutManager.usageBoundsForTextContainer.width

            // Frame should be at least text width + custom gutter width
            XCTAssertGreaterThanOrEqual(stTextView.frame.width, textWidth + 64 - 1, "Frame should include both text content and custom gutter")
        }

        @MainActor
        func testDataSourceQueriedDuringLayout() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.setString("Line 1\nLine 2\nLine 3")

            var queriedLines: [(Int, String)] = []
            let dataSource = TestGutterDataSource { lineNumber, content in
                queriedLines.append((lineNumber, content))
                let label = NSTextField(labelWithString: "\(lineNumber)")
                return label
            }

            stTextView.customGutterWidth = 40
            stTextView.gutterLineViewDataSource = dataSource
            stTextView.layout()

            XCTAssertFalse(queriedLines.isEmpty, "Data source should be queried during layout")
            // All queried line numbers should be 1-based and positive
            for (lineNumber, _) in queriedLines {
                XCTAssertGreaterThan(lineNumber, 0, "Line numbers should be 1-based")
            }
        }

        @MainActor
        func testCustomGutterContainerCleanedUpWhenWidthZeroed() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.setString("Hello")

            let dataSource = TestGutterDataSource { _, _ in NSView() }
            stTextView.customGutterWidth = 40
            stTextView.gutterLineViewDataSource = dataSource
            stTextView.layout()

            XCTAssertNotNil(stTextView.customGutterContainerView, "Container should exist when custom gutter is configured")

            // Disable the custom gutter
            stTextView.customGutterWidth = 0

            XCTAssertNil(stTextView.customGutterContainerView, "Container should be removed when custom gutter width is zeroed")
        }

        @MainActor
        func testCustomGutterContainerCleanedUpWhenDataSourceNilled() {
            let stTextView = STTextView()
            stTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
            stTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            stTextView.setString("Hello")

            let dataSource = TestGutterDataSource { _, _ in NSView() }
            stTextView.customGutterWidth = 40
            stTextView.gutterLineViewDataSource = dataSource
            stTextView.layout()

            XCTAssertNotNil(stTextView.customGutterContainerView, "Container should exist when custom gutter is configured")

            // Nil the data source
            stTextView.gutterLineViewDataSource = nil

            XCTAssertNil(stTextView.customGutterContainerView, "Container should be removed when data source is nilled")
        }

    }

    // MARK: - Test Helpers

    /// A concrete ``STGutterLineViewDataSource`` for testing.
    private class TestGutterDataSource: STGutterLineViewDataSource {
        let factory: (Int, String) -> NSView

        init(factory: @escaping (Int, String) -> NSView) {
            self.factory = factory
        }

        func textView(_ textView: STTextView, viewForGutterLine lineNumber: Int, content: String) -> NSView {
            factory(lineNumber, content)
        }
    }

#endif
