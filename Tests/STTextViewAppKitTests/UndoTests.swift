#if os(macOS)
import XCTest
@testable import STTextViewAppKit

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
        textView.keyDown(with: try .create(characters: "a"))
        textView.keyDown(with: try .create(characters: "b"))
        textView.keyDown(with: try .create(key: .return))
        textView.keyDown(with: try .create(characters: "c"))
        textView.keyDown(with: try .create(characters: "d"))
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
}
#endif
