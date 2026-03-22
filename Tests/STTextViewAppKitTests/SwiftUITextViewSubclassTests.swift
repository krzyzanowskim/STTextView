#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    @MainActor
    final class SwiftUITextViewSubclassTests: XCTestCase {

        func testScrollableTextViewReturnsSTTextViewByDefault() throws {
            let scrollView = STTextView.scrollableTextView()
            let documentView = try XCTUnwrap(scrollView.documentView as? STTextView)

            XCTAssertTrue(type(of: documentView) == STTextView.self)
        }

        func testScrollableTextViewReturnsSubclassWhenCalledOnSubclass() throws {
            let scrollView = CustomTextView.scrollableTextView()
            let documentView = try XCTUnwrap(scrollView.documentView as? STTextView)

            XCTAssertTrue(documentView is CustomTextView)
        }
    }

    private final class CustomTextView: STTextView {}
#endif
