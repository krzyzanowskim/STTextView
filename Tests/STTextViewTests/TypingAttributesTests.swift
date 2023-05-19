import XCTest
@testable import STTextView

class TypingAttributesTests : XCTestCase {

    func testDefaultSetup() {
        let textView = STTextView()
        XCTAssertEqual(textView.typingAttributes.count, 3)
        XCTAssertNotNil(textView.typingAttributes[.paragraphStyle])
        XCTAssertNotNil(textView.typingAttributes[.font])
        XCTAssertNotNil(textView.typingAttributes[.foregroundColor])
    }

    func testSetTypingAttributes() {
        let textView = STTextView()
        XCTAssertFalse(textView.typingAttributes.isEmpty)
        let beforeChange = textView.typingAttributes
        textView.typingAttributes[.font] = NSFont.systemFont(ofSize: 44)
        let afterChange = textView.typingAttributes

        XCTAssertNotEqual(beforeChange[.font] as? NSFont, afterChange[.font] as? NSFont)

        XCTAssertNotNil(afterChange[.paragraphStyle] as? NSParagraphStyle)
        XCTAssertNotNil(afterChange[.foregroundColor] as? NSColor)
        XCTAssertEqual(beforeChange[.paragraphStyle] as? NSParagraphStyle, afterChange[.paragraphStyle] as? NSParagraphStyle)
        XCTAssertEqual(beforeChange[.foregroundColor] as? NSColor, afterChange[.foregroundColor] as? NSColor)
    }

    func testSetFontEmptyContent() {
        let textView = STTextView()
        XCTAssertNotNil(textView.font)

        textView.font = NSFont.boldSystemFont(ofSize: 99)
        XCTAssertNotNil(textView.font)
        XCTAssertEqual(textView.font, NSFont.boldSystemFont(ofSize: 99))
        XCTAssertEqual(textView.font, textView.typingAttributes[.font] as? NSFont)

        textView.font = nil
        XCTAssertEqual(textView.font, NSFont.boldSystemFont(ofSize: 99))
        XCTAssertEqual(textView.font, textView.typingAttributes[.font] as? NSFont)
    }

    func testSetFontContent() {
        let textView = STTextView()
        textView.string = "0123456789"
        XCTAssertNotNil(textView.font)

        textView.font = NSFont.boldSystemFont(ofSize: 99)
        XCTAssertNotNil(textView.font)
        XCTAssertEqual(textView.font, NSFont.boldSystemFont(ofSize: 99))
        XCTAssertEqual(textView.font, textView.typingAttributes[.font] as? NSFont)

        textView.font = nil
        XCTAssertEqual(textView.font, NSFont.boldSystemFont(ofSize: 99))
        XCTAssertEqual(textView.font, textView.typingAttributes[.font] as? NSFont)
    }

    func testSetFontContentRange() {
        let textView = STTextView()
        textView.string = "0123456789"
        let beforeChange = textView.typingAttributes
        // "12" is size of 55
        textView.addAttributes([.font: NSFont.systemFont(ofSize: 55)], range: NSRange(location: 1, length: 2))
        // "89" is size of 66
        textView.addAttributes([.font: NSFont.systemFont(ofSize: 66)], range: NSRange(location: 8, length: 2))

        print(textView.attributedString())
        // Move insertion point

        // No change at index 0
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        XCTAssertEqual(textView.typingAttributes[.font] as? NSFont, beforeChange[.font] as? NSFont)

        // Change at index 1
        textView.setSelectedRange(NSRange(location: 1, length: 0))
        XCTAssertNotEqual(textView.typingAttributes[.font] as? NSFont, beforeChange[.font] as? NSFont)

        // Change at index 2
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        XCTAssertNotEqual(textView.typingAttributes[.font] as? NSFont, beforeChange[.font] as? NSFont)

        // No change at index 3
        textView.setSelectedRange(NSRange(location: 3, length: 0))
        XCTAssertEqual(textView.typingAttributes[.font] as? NSFont, beforeChange[.font] as? NSFont)

        // Change at index 9
        textView.setSelectedRange(NSRange(location: 9, length: 0))
        XCTAssertNotEqual(textView.typingAttributes[.font] as? NSFont, beforeChange[.font] as? NSFont)
    }
}
