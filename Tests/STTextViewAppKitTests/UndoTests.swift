#if os(macOS)
    import AppKit
    import XCTest
    @testable import STTextViewAppKit

    @MainActor
    final class UndoTests: XCTestCase {
        func testInsertingAtEndAndUndo() {
            let textView = STTextView()
            textView.insertText("a")
            textView.insertText("b")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "a")
            XCTAssertEqual(textView.selectedRange(), NSRange(location: 1, length: 0))
        }

        func testPasteLongerThanCurrentContentUndo() {
            let textView = STTextView()
            textView.text! = "first line\nsecond line"
            textView.setSelectedRange(NSRange(location: 11, length: 11))
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("new second line\nthird line", forType: .string)

            textView.paste(nil)
            XCTAssertEqual(textView.text!, "first line\nnew second line\nthird line")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "first line\nsecond line")
            textView.setSelectedRange(NSRange(location: 11, length: 11))
        }

        func testInsertBetweenAndUndo() {
            let textView = STTextView()
            textView.insertText("123456789")
            textView.setSelectedRange(NSRange(location: 3, length: 3))

            textView.insertText("a")
            XCTAssertEqual(textView.text!, "123a789")

            textView.undo(nil)
            XCTAssertEqual(textView.selectedRange(), NSRange(location: 3, length: 3))
            XCTAssertEqual(textView.text!, "123456789")
        }

        func testTypingCoalescing() throws {
            let textView = STTextView()
            try textView.keyDown(with: .create(characters: "a"))
            try textView.keyDown(with: .create(characters: "b"))
            try textView.keyDown(with: .create(key: .return))
            try textView.keyDown(with: .create(characters: "c"))
            try textView.keyDown(with: .create(characters: "d"))
            XCTAssertEqual(textView.text!, "ab\ncd")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "ab\n")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "ab")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "")
        }

        func testRedo() {
            let textView = STTextView()
            textView.insertText("123456789")
            textView.setSelectedRange(NSRange(location: 3, length: 3))

            textView.insertText("a")
            XCTAssertEqual(textView.text!, "123a789")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "123456789")

            textView.undo(nil)
            XCTAssertEqual(textView.text!, "")

            textView.redo(nil)
            XCTAssertEqual(textView.text!, "123456789")

            textView.redo(nil)
            XCTAssertEqual(textView.text!, "123a789")
        }

        func testSelectionScrollLocationSkipsSelectionsAlreadyInViewport() {
            let harness = ScrollViewHarness()
            let textView = harness.textView

            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.text = Array(repeating: "alpha beta gamma delta epsilon zeta eta theta iota kappa", count: 200).joined(separator: "\n")

            harness.flushLayout()

            XCTAssertNil(textView.textLocationForScrollingSelection(toVisible: textView.textLayoutManager.documentRange))
        }

        func testSelectionScrollLocationUsesNearestSelectionEdgeOutsideViewport() throws {
            let harness = ScrollViewHarness()
            let textView = harness.textView

            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.text = Array(repeating: "alpha beta gamma delta epsilon zeta eta theta iota kappa", count: 200).joined(separator: "\n")

            harness.flushLayout()

            guard let initialViewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange else {
                return XCTFail("Missing initial viewport range")
            }

            let documentStart = textView.textLayoutManager.documentRange.location
            let initialViewportEndOffset = textView.textContentManager.offset(from: documentStart, to: initialViewportRange.endLocation)
            let afterRange = try XCTUnwrap(
                NSTextRange(
                    NSRange(location: min(initialViewportEndOffset + 1, textView.text!.utf16.count - 1), length: 1),
                    in: textView.textContentManager
                )
            )
            let afterLocation = try XCTUnwrap(textView.textLocationForScrollingSelection(toVisible: afterRange))
            XCTAssertEqual(
                textView.textContentManager.offset(from: documentStart, to: afterLocation),
                NSRange(afterRange, in: textView.textContentManager).location
            )

            harness.scrollToBottom()

            guard let viewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange else {
                return XCTFail("Missing viewport range")
            }

            let viewportStartOffset = textView.textContentManager.offset(from: documentStart, to: viewportRange.location)
            let beforeRange = try XCTUnwrap(
                NSTextRange(
                    NSRange(location: 0, length: max(1, viewportStartOffset - 1)),
                    in: textView.textContentManager
                )
            )
            let beforeLocation = try XCTUnwrap(textView.textLocationForScrollingSelection(toVisible: beforeRange))

            XCTAssertEqual(
                textView.textContentManager.offset(from: documentStart, to: beforeLocation),
                NSMaxRange(NSRange(beforeRange, in: textView.textContentManager))
            )
        }
    }

    @MainActor
    private final class ScrollViewHarness {
        let window: NSWindow
        let scrollView: NSScrollView
        let textView: STTextView

        init() {
            let scrollView = STTextView.scrollableTextView()
            self.window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            self.scrollView = scrollView
            self.textView = scrollView.documentView as! STTextView

            guard let contentView = window.contentView else {
                fatalError("Missing window content view")
            }

            scrollView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(scrollView)
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            window.makeKeyAndOrderFront(nil)
        }

        func flushLayout() {
            window.contentView?.layoutSubtreeIfNeeded()
            textView.layoutSubtreeIfNeeded()

            RunLoop.current.run(until: Date().addingTimeInterval(0.01))

            window.contentView?.layoutSubtreeIfNeeded()
            textView.layoutSubtreeIfNeeded()
        }

        func scrollToBottom() {
            let documentHeight = textView.frame.height
            let visibleHeight = scrollView.contentView.bounds.height
            guard documentHeight > visibleHeight else {
                return
            }

            scrollView.contentView.scroll(to: CGPoint(x: 0, y: documentHeight - visibleHeight))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            flushLayout()
        }
    }
#endif
