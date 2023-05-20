import XCTest
@testable import STTextView

class ContentTests : XCTestCase {

    func testContentUpdate() {
        let textView = STTextView()
        XCTAssertTrue(textView.string.isEmpty)
        XCTAssertEqual(textView.attributedString().length, 0)

        textView.string = "1234"
        XCTAssertEqual(textView.string.count, 4)
        XCTAssertEqual(textView.attributedString().length, 4)

        textView.string = "5678"
        XCTAssertEqual(textView.string.count, 4)
        XCTAssertEqual(textView.attributedString().length, 4)

        textView.setAttributedString(NSAttributedString(string: "12345"))
        XCTAssertEqual(textView.string.count, 5)
        XCTAssertEqual(textView.attributedString().length, 5)

        textView.setAttributedString(NSAttributedString(string: "6789"))
        XCTAssertEqual(textView.string.count, 4)
        XCTAssertEqual(textView.attributedString().length, 4)

        textView.string = ""
        XCTAssertEqual(textView.string.count, 0)
        XCTAssertEqual(textView.attributedString().length, 0)
    }

    func testContentUpdateStringAfterAttributedString() {
        let textView = STTextView()
        textView.setAttributedString(NSAttributedString(string: "1234"))
        textView.string = ""
        XCTAssertEqual(textView.string.count, 0)
        XCTAssertEqual(textView.attributedString().length, 0)
    }

    func testFontChange() {
        let textView = STTextView()
        XCTAssertNotNil(textView.font)
        XCTAssertNotNil(textView.typingAttributes[.font])

        textView.font = NSFont.systemFont(ofSize: 24)
        XCTAssertNotNil(textView.font)
        XCTAssertEqual(textView.font, NSFont.systemFont(ofSize: 24))
        XCTAssertEqual(textView.typingAttributes[.font] as! NSFont, NSFont.systemFont(ofSize: 24))

        textView.font = NSFont.systemFont(ofSize: 96)
        XCTAssertNotNil(textView.font)
        XCTAssertEqual(textView.font, NSFont.systemFont(ofSize: 96))
        XCTAssertEqual(textView.typingAttributes[.font] as! NSFont, NSFont.systemFont(ofSize: 96))

        XCTExpectFailure("nil NSFont given")
        textView.font = nil
        XCTAssertNotNil(textView.font)
        XCTAssertNotNil(textView.typingAttributes[.font])
    }
}
