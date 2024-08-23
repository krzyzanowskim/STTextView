#if os(macOS)
import XCTest
@testable import STTextViewAppKit

final class TextSelectionNavigationTests: XCTestCase {
    func testMoveLeft() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveLeft(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
        textView.moveLeft(nil)
        XCTAssertEqual(NSRange(location: 3, length: 0), textView.selectedRange())
    }

    func testMoveLeftAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveLeftAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
        textView.moveLeftAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 3, length: 2), textView.selectedRange())
    }

    func testMoveRight() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.moveRight(nil)
        XCTAssertEqual(NSRange(location: 2, length: 0), textView.selectedRange())
        textView.moveRight(nil)
        XCTAssertEqual(NSRange(location: 3, length: 0), textView.selectedRange())
    }

    func testMoveRightAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.moveRightAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 1), textView.selectedRange())
        textView.moveRightAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 2), textView.selectedRange())
        textView.moveRightAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 3), textView.selectedRange())
    }

    func testMoveUp() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 9, length: 0))

        textView.moveUp(nil)
        XCTAssertEqual(NSRange(location: 5, length: 0), textView.selectedRange())
        textView.moveUp(nil)
        XCTAssertEqual(NSRange(location: 1, length: 0), textView.selectedRange())
    }

    func testMoveUpAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 9, length: 0))

        textView.moveUpAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 4), textView.selectedRange())
    }

    func testMoveDown() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.moveDown(nil)
        XCTAssertEqual(NSRange(location: 5, length: 0), textView.selectedRange())
    }

    func testMoveDownAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.moveDownAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 4), textView.selectedRange())
    }

    func testMoveForward() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.moveForward(nil)
        XCTAssertEqual(NSRange(location: 2, length: 0), textView.selectedRange())
        textView.moveForward(nil)
        XCTAssertEqual(NSRange(location: 3, length: 0), textView.selectedRange())
        textView.moveForward(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
    }

    func testMoveForwardAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        textView.moveForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 1), textView.selectedRange())
        textView.moveForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 2), textView.selectedRange())
        textView.moveForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 3), textView.selectedRange())
    }

    func testMoveBackward() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveBackward(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
        textView.moveBackward(nil)
        XCTAssertEqual(NSRange(location: 3, length: 0), textView.selectedRange())
        textView.moveBackward(nil)
        XCTAssertEqual(NSRange(location: 2, length: 0), textView.selectedRange())
    }

    func testMoveBackwardAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 4, length: 0))

        textView.moveBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 3, length: 1), textView.selectedRange())
        textView.moveBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 2, length: 2), textView.selectedRange())
        textView.moveBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 1, length: 3), textView.selectedRange())
    }

    func testMoveWordLeft() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        textView.moveWordLeft(nil)
        XCTAssertEqual(NSRange(location: 0, length: 0), textView.selectedRange())
    }

    func testMoveWordLeftAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        textView.moveWordLeftAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 0), textView.selectedRange())
    }

    func testMoveWordRight() {
        let textView = STTextView()
        textView.attributedText = .init("Hello world\nSecond Line")
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        textView.moveWordRight(nil)
        XCTAssertEqual(NSRange(location: 5, length: 0), textView.selectedRange())
        textView.moveWordRight(nil)
        XCTAssertEqual(NSRange(location: 11, length: 0), textView.selectedRange())
        textView.moveWordRight(nil)
        XCTAssertEqual(NSRange(location: 18, length: 0), textView.selectedRange())
    }

    func testMoveWordRightAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("Hello world\nSecond Line")
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        textView.moveWordRightAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 5), textView.selectedRange())
        textView.moveWordRightAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 11), textView.selectedRange())
        textView.moveWordRightAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 18), textView.selectedRange())
    }

    func testMoveWordForward() {
        let textView = STTextView()
        textView.attributedText = .init("Hello world\nSecond Line")
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        textView.moveWordForward(nil)
        XCTAssertEqual(NSRange(location: 5, length: 0), textView.selectedRange())
        textView.moveWordForward(nil)
        XCTAssertEqual(NSRange(location: 11, length: 0), textView.selectedRange())
        textView.moveWordForward(nil)
        XCTAssertEqual(NSRange(location: 18, length: 0), textView.selectedRange())
    }

    func testMoveWordForwardAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("Hello world\nSecond Line")
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        textView.moveWordForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 5), textView.selectedRange())
        textView.moveWordForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 11), textView.selectedRange())
        textView.moveWordForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 18), textView.selectedRange())
    }

    func testMoveWordBackward() {
        let textView = STTextView()
        textView.attributedText = .init("Hello world\nSecond Line")
        textView.setSelectedRange(NSRange(location: 12, length: 0))

        textView.moveWordBackward(nil)
        XCTAssertEqual(NSRange(location: 6, length: 0), textView.selectedRange())
        textView.moveWordBackward(nil)
        XCTAssertEqual(NSRange(location: 0, length: 0), textView.selectedRange())
    }

    func testMoveWordBackwardAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("Hello world\nSecond Line")
        textView.setSelectedRange(NSRange(location: 12, length: 0))

        textView.moveWordBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 6, length: 6), textView.selectedRange())
        textView.moveWordBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 12), textView.selectedRange())
    }

    func testMoveToBeginningOfLine() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToBeginningOfLine(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
        textView.moveToBeginningOfLine(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
    }

    func testMoveToBeginningOfLineAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToBeginningOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
        textView.moveToBeginningOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
    }

    func testMoveToLeftEndOfLine() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToLeftEndOfLine(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
        textView.moveToLeftEndOfLine(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
    }

    func testMoveToLeftEndOfLineAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToLeftEndOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
        textView.moveToLeftEndOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
    }

    func testMoveToEndOfLine() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToEndOfLine(nil)
        XCTAssertEqual(NSRange(location: 7, length: 0), textView.selectedRange())
        textView.moveToEndOfLine(nil)
        XCTAssertEqual(NSRange(location: 7, length: 0), textView.selectedRange())
    }

    func testMoveToEndOfLineAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToEndOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
        textView.moveToEndOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
    }

    func testMoveToRightEndOfLine() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToRightEndOfLine(nil)
        XCTAssertEqual(NSRange(location: 7, length: 0), textView.selectedRange())
        textView.moveToRightEndOfLine(nil)
        XCTAssertEqual(NSRange(location: 7, length: 0), textView.selectedRange())
    }

    func testMoveToRightEndOfLineAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToRightEndOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
        textView.moveToRightEndOfLineAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
    }

    func testMoveParagraphForwardAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveParagraphForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
        textView.moveParagraphForwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 5), textView.selectedRange())
    }

    func testMoveParagraphBackwardAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveParagraphBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
        textView.moveParagraphBackwardAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 5), textView.selectedRange())
    }

    func testMoveToBeginningOfParagraph() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToBeginningOfParagraph(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
        textView.moveToBeginningOfParagraph(nil)
        XCTAssertEqual(NSRange(location: 4, length: 0), textView.selectedRange())
    }

    func testMoveToBeginningOfParagraphAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToBeginningOfParagraphAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
        textView.moveToBeginningOfParagraphAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 4, length: 1), textView.selectedRange())
    }

    func testMoveToEndOfParagraph() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToEndOfParagraph(nil)
        XCTAssertEqual(NSRange(location: 7, length: 0), textView.selectedRange())
        textView.moveToEndOfParagraph(nil)
        XCTAssertEqual(NSRange(location: 7, length: 0), textView.selectedRange())
    }

    func testMoveToEndOfParagraphAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToEndOfParagraphAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
        textView.moveToEndOfParagraphAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 2), textView.selectedRange())
    }

    func testMoveToBeginningOfDocument() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToBeginningOfDocument(nil)
        XCTAssertEqual(NSRange(location: 0, length: 0), textView.selectedRange())
        textView.moveToBeginningOfDocument(nil)
        XCTAssertEqual(NSRange(location: 0, length: 0), textView.selectedRange())
    }

    func testMoveToBeginningOfDocumentAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToBeginningOfDocumentAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 5), textView.selectedRange())
        textView.moveToBeginningOfDocumentAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 0, length: 5), textView.selectedRange())
    }

    func testMoveToEndOfDocument() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToEndOfDocument(nil)
        XCTAssertEqual(NSRange(location: 10, length: 0), textView.selectedRange())
        textView.moveToEndOfDocument(nil)
        XCTAssertEqual(NSRange(location: 10, length: 0), textView.selectedRange())
    }

    func testMoveToEndOfDocumentAndModifySelection() {
        let textView = STTextView()
        textView.attributedText = .init("012\n456\n89")
        textView.setSelectedRange(NSRange(location: 5, length: 0))

        textView.moveToEndOfDocumentAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 5), textView.selectedRange())
        textView.moveToEndOfDocumentAndModifySelection(nil)
        XCTAssertEqual(NSRange(location: 5, length: 5), textView.selectedRange())
    }
}

extension NSTextView {
    func setAttributedString(_ attributedString: NSAttributedString) {
        textStorage?.setAttributedString(attributedString)
    }
}
#endif
