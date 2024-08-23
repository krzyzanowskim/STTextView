#if os(macOS)
import XCTest
@testable import STTextViewAppKit

class ContentTests : XCTestCase {

    func testContentUpdate() {
        let textView = STTextView()
        XCTAssertTrue(textView.text!.isEmpty)
        XCTAssertEqual(textView.attributedString().length, 0)

        textView.text = "1234"
        XCTAssertEqual(textView.text!.count, 4)
        XCTAssertEqual(textView.attributedString().length, 4)

        textView.text = "5678"
        XCTAssertEqual(textView.text!.count, 4)
        XCTAssertEqual(textView.attributedString().length, 4)

        textView.attributedText = NSAttributedString(string: "12345")
        XCTAssertEqual(textView.text!.count, 5)
        XCTAssertEqual(textView.attributedString().length, 5)

        textView.attributedText = NSAttributedString(string: "6789")
        XCTAssertEqual(textView.text!.count, 4)
        XCTAssertEqual(textView.attributedString().length, 4)

        textView.text = ""
        XCTAssertEqual(textView.text!.count, 0)
        XCTAssertEqual(textView.attributedString().length, 0)
    }

    func testContentUpdateStringAfterAttributedString() {
        let textView = STTextView()
        textView.attributedText = NSAttributedString(string: "1234")
        textView.text = ""
        XCTAssertEqual(textView.text!.count, 0)
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

        XCTAssertNotNil(textView.font)
        XCTAssertNotNil(textView.typingAttributes[.font])
    }
}
#endif
