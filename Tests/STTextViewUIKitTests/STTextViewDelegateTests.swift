#if os(iOS)
import XCTest
@testable import STTextViewUIKit

class STTextViewDelegateTests : XCTestCase {

    func testInitialState() {
        let textView = STTextView()
        // XCTAssertNil(textView.selectedTextRange)
    }

}
#endif
