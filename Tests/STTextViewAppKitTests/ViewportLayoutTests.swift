#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    private struct InvalidatingPlugin: STPlugin {
        func setUp(context: any Context) {
            let textView = context.textView
            context.events.onDidLayoutViewport { _ in
                MainActor.assumeIsolated {
                    textView.setNeedsLayoutSafe()
                }
            }
        }
    }

    final class ViewportLayoutTests: XCTestCase {

        @MainActor
        private func makeScrollableTextView() -> (NSScrollView, STTextView, NSWindow) {
            let scrollView = STTextView.scrollableTextView()
            scrollView.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
            let textView = scrollView.documentView as! STTextView
            textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

            let window = NSWindow(contentRect: scrollView.frame, styleMask: [.titled], backing: .buffered, defer: false)
            window.contentView = scrollView
            window.makeKeyAndOrderFront(nil)
            return (scrollView, textView, window)
        }

        @MainActor
        func testNotVerticallyResizableFillsClipView() {
            let (scrollView, textView, _) = makeScrollableTextView()
            textView.setString((1 ... 2000).map { "Line \($0)" }.joined(separator: "\n"))
            scrollView.layoutSubtreeIfNeeded()

            // The estimated document height is well beyond the 300pt clip view.
            XCTAssertGreaterThan(textView.frame.height, 10000, "Vertically resizable view grows to fit the document")

            // Turning vertical resizing off must shrink the document view back to the clip
            // view instead of leaving it scrollable over the stale, taller frame.
            textView.isVerticallyResizable = false
            textView.needsLayout = true
            textView.layoutSubtreeIfNeeded()

            XCTAssertEqual(textView.frame.height, scrollView.contentView.bounds.height, accuracy: 1.0)
        }

        @MainActor
        func testNotVerticallyResizableInPreFramedScrollView() {
            // When the scroll view is already framed as the document view is attached,
            // NSScrollView doesn't tile the document view into place, so the text view has
            // to size itself. Deriving the height from its own frame leaves it empty.
            let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
            let textView = scrollView.documentView as! STTextView
            textView.isVerticallyResizable = false
            textView.setString((1 ... 2000).map { "Line \($0)" }.joined(separator: "\n"))
            scrollView.layoutSubtreeIfNeeded()
            textView.layoutSubtreeIfNeeded()

            XCTAssertEqual(textView.frame.height, 300, accuracy: 1.0)
            XCTAssertGreaterThan(textView.textLayoutManager.textViewportLayoutController.viewportBounds.height, 0)
        }

        @MainActor
        func testLongLineIsFullyReachable() {
            let (scrollView, textView, _) = makeScrollableTextView()
            textView.isHorizontallyResizable = true
            textView.showsLineNumbers = true
            textView.setString(String(repeating: "x", count: 300))
            scrollView.layoutSubtreeIfNeeded()

            // usageBoundsForTextContainer is offset by the leading line fragment padding, so
            // the trailing edge of the longest line is at maxX, not at size.width. The
            // content carries the same padding again on the trailing side.
            let usageBounds = textView.textLayoutManager.usageBoundsForTextContainer
            let gutterWidth = textView.gutterView?.frame.width ?? 0
            let textRightEdge = usageBounds.maxX + gutterWidth
            XCTAssertGreaterThanOrEqual(textView.frame.width, textRightEdge)
            XCTAssertEqual(
                textView.frame.width - textRightEdge,
                textView.textContainer.lineFragmentPadding,
                accuracy: 1.0,
                "Trailing slack should match the leading line fragment padding"
            )
        }

        @MainActor
        func testPostLayoutActionRunsWhenPluginInvalidatesLayout() {
            let (scrollView, textView, _) = makeScrollableTextView()
            textView.addPlugin(InvalidatingPlugin())
            textView.setString((1 ... 200).map { "Line \($0)" }.joined(separator: "\n"))
            scrollView.layoutSubtreeIfNeeded()

            var didRun = false
            textView.postLayoutAction = { didRun = true }
            textView.needsLayout = true
            textView.layoutSubtreeIfNeeded()

            XCTAssertTrue(didRun, "A plugin invalidating layout must not starve postLayoutAction")
        }
    }
#endif
