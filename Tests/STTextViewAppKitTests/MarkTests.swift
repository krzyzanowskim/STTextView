#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    class MarkTests: XCTestCase {

        func testSwapWithMark() {
            let textView = STTextView()
            textView.text = "abc def"

            textView.textSelection = NSRange(location: 0, length: 3)
            textView.setMark(nil)
            textView.textSelection = NSRange(location: 4, length: 3)

            textView.swapWithMark(nil)
            XCTAssertEqual(textView.textSelection, NSRange(location: 0, length: 3))

            textView.swapWithMark(nil)
            XCTAssertEqual(textView.textSelection, NSRange(location: 4, length: 3))
        }

        func testSelectToMark() {
            let textView = STTextView()
            textView.text = "abc def ghi"

            textView.textSelection = NSRange(location: 0, length: 3)
            textView.setMark(nil)
            textView.textSelection = NSRange(location: 8, length: 0)

            textView.selectToMark(nil)
            XCTAssertEqual(textView.textSelection, NSRange(location: 0, length: 8))
        }

        func testDeleteToMarkFeedsKillRing() {
            let textView = STTextView()
            textView.text = "abc def ghi"

            textView.textSelection = NSRange(location: 4, length: 0)
            textView.setMark(nil)
            textView.textSelection = NSRange(location: 8, length: 0)

            textView.deleteToMark(nil)
            XCTAssertEqual(textView.text, "abc ghi")

            textView.textSelection = NSRange(location: 0, length: 0)
            textView.yank(nil)
            XCTAssertEqual(textView.text, "def abc ghi")
        }

        func testStaleMarkIsClampedAfterEdits() {
            let textView = STTextView()
            textView.text = "abcdefgh"

            textView.textSelection = NSRange(location: 8, length: 0)
            textView.setMark(nil)
            textView.text = "abc"
            textView.textSelection = NSRange(location: 0, length: 0)

            textView.selectToMark(nil)
            XCTAssertEqual(textView.textSelection, NSRange(location: 0, length: 3))
        }

        func testCommandsWithoutMarkAreNoOps() {
            let textView = STTextView()
            textView.text = "abc"
            textView.textSelection = NSRange(location: 1, length: 0)

            textView.swapWithMark(nil)
            textView.selectToMark(nil)
            textView.deleteToMark(nil)

            XCTAssertEqual(textView.text, "abc")
            XCTAssertEqual(textView.textSelection, NSRange(location: 1, length: 0))
        }

    }

#endif
