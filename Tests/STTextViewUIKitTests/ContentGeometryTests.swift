#if os(iOS) || targetEnvironment(macCatalyst)
    import XCTest
    @testable import STTextViewUIKit

    @MainActor
    final class ContentGeometryTests: XCTestCase {

        private func makeTextView(showsLineNumbers: Bool) -> STTextView {
            let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
            window.addSubview(textView)
            window.makeKeyAndVisible()
            textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            textView.isHorizontallyResizable = true
            textView.showsLineNumbers = showsLineNumbers
            textView.text = String(repeating: "x", count: 300)
            textView.layoutIfNeeded()
            return textView
        }

        /// The full width of the longest line has to be reachable by scrolling, with the
        /// leading line fragment padding mirrored on the trailing side. Keep in sync with
        /// the AppKit `ViewportLayoutTests.testLongLineIsFullyReachable`.
        private func assertTrailingPadding(_ textView: STTextView, file: StaticString = #filePath, line: UInt = #line) {
            let usageBounds = textView.textLayoutManager.usageBoundsForTextContainer
            let gutterWidth = textView.gutterView?.frame.width ?? 0
            let textRightEdge = gutterWidth + textView.textContainerInset.left + usageBounds.maxX

            XCTAssertGreaterThanOrEqual(textView.contentSize.width, textRightEdge, file: file, line: line)
            XCTAssertEqual(
                textView.contentSize.width - textRightEdge,
                textView.textContainer.lineFragmentPadding + textView.textContainerInset.right,
                accuracy: 0.5,
                "Trailing slack should match the leading line fragment padding",
                file: file,
                line: line
            )
        }

        func testLongLineTrailingPadding() {
            assertTrailingPadding(makeTextView(showsLineNumbers: false))
        }

        func testLongLineTrailingPaddingWithGutter() {
            assertTrailingPadding(makeTextView(showsLineNumbers: true))
        }

        func testSizeToFitMatchesViewportDrivenSizing() {
            let textView = makeTextView(showsLineNumbers: true)
            let viewportDrivenWidth = textView.contentSize.width

            textView.sizeToFit()
            textView.layoutIfNeeded()

            XCTAssertEqual(textView.contentSize.width, viewportDrivenWidth, accuracy: 0.5)
            assertTrailingPadding(textView)
        }

        func testWrappedTextTracksViewportWidth() {
            let textView = makeTextView(showsLineNumbers: false)
            textView.isHorizontallyResizable = false
            textView.layoutIfNeeded()

            XCTAssertEqual(textView.contentSize.width, textView.bounds.width, accuracy: 0.5)
        }
    }
#endif
