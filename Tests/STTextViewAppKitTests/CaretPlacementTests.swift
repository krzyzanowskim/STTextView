#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    final class CaretPlacementTests: XCTestCase {
        private final class CaretDrawingTextView: STTextView {
            override var shouldDrawInsertionPoint: Bool { true }
        }

        private func makeTextView(_ text: String, width: CGFloat = 400) -> (STTextView, NSWindow) {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
            let textView = CaretDrawingTextView(frame: NSRect(x: 0, y: 0, width: width, height: 300))
            window.contentView = textView
            textView.isHorizontallyResizable = false
            textView.text = text
            textView.layout()
            return (textView, window)
        }

        private func caretMinY(_ textView: STTextView) -> CGFloat? {
            textView.updateInsertionPointStateAndRestartTimer()
            return textView.contentView.subviews.first { $0 is STInsertionPointView }?.frame.minY
        }

        func testCaretAtEndOfWrappedLineStaysOnThatLine() {
            let (textView, window) = makeTextView("aaaa bbbb cccc dddd eeee ffff gggg hhhh", width: 120)
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            let firstLineY = caretMinY(textView)

            textView.moveToEndOfLine(nil)
            XCTAssertEqual(caretMinY(textView), firstLineY)

            textView.text = "abc\ndef"
            let secondLineStart = NSTextRange(NSRange(location: 4, length: 0), in: textView.textContentManager)!
            textView.textLayoutManager.textSelections = [NSTextSelection(range: secondLineStart, affinity: .upstream, granularity: .character)]
            XCTAssertNotEqual(caretMinY(textView), firstLineY, "a caret after a newline stays on its own line")
            _ = window
        }

        func testPageDownMovesCaret() {
            let (textView, window) = makeTextView((0..<200).map { "line \($0)" }.joined(separator: "\n"))
            textView.setSelectedRange(NSRange(location: 0, length: 0))

            textView.pageDown(nil)
            let caret = textView.selectedRange()
            XCTAssertGreaterThan(caret.location, 0)
            XCTAssertEqual(caret.length, 0)

            textView.pageDownAndModifySelection(nil)
            XCTAssertEqual(textView.selectedRange().location, caret.location)
            XCTAssertGreaterThan(textView.selectedRange().length, 0)
            _ = window
        }
    }
#endif
