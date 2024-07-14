#if os(macOS)
import XCTest
@testable import STTextViewAppKit

class TextViewTests : XCTestCase {

    func testNoInitialSelection() {
        let textView = STTextView()
        XCTAssertNil(textView.selectedTextRange())
    }

}

#endif
