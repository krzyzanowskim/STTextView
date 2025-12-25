#if os(iOS) || targetEnvironment(macCatalyst)
    import XCTest
    @testable import STTextViewUIKit

    class STTextViewDelegateTests: XCTestCase {

        func testInitialState() {
            let textView = STTextView()
            XCTAssertNil(textView.selectedTextRange)
        }

        func testTextDelegate1() {
            let textView = STTextView()
            let willChangeTextExpecation = expectation(description: "willChangeText")
            let didChangeSelectionExpecation = expectation(description: "didChangeSelection")
            didChangeSelectionExpecation.expectedFulfillmentCount = 3
            let didChangeTextExpecation = expectation(description: "didChangeText")

            let textViewDelegate = TextViewDelegate(
                willChangeText: { _ in
                    willChangeTextExpecation.fulfill()
                }, didChangeText: { _ in
                    didChangeTextExpecation.fulfill()
                }, didChangeSelection: { _ in
                    didChangeSelectionExpecation.fulfill()
                }
            )

            textView.textDelegate = textViewDelegate
            textView.text = "0123456789"

            waitForExpectations(timeout: 1)
        }

    }


    private class TextViewDelegate: STTextViewDelegate {
        var willChangeText: (Notification) -> Void
        var didChangeText: (Notification) -> Void
        var didChangeSelection: (Notification) -> Void
        var shouldChangeTextIn: (_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool
        var willChangeTextIn: (_ affectedCharRange: NSTextRange, _ replacementString: String) -> Void
        var didChangeTextIn: (_ affectedCharRange: NSTextRange, _ replacementString: String) -> Void

        init(
            willChangeText: @escaping (Notification) -> Void = { _ in },
            didChangeText: @escaping (Notification) -> Void = { _ in },
            didChangeSelection: @escaping (Notification) -> Void = { _ in },
            shouldChangeTextIn: @escaping (_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool = { _, _ in true },
            willChangeTextIn: @escaping (_ affectedCharRange: NSTextRange, _ replacementString: String) -> Void = { _, _ in },
            didChangeTextIn: @escaping (_ affectedCharRange: NSTextRange, _ replacementString: String) -> Void = { _, _ in }
        ) {
            self.willChangeText = willChangeText
            self.didChangeText = didChangeText
            self.didChangeSelection = didChangeSelection
            self.shouldChangeTextIn = shouldChangeTextIn
            self.willChangeTextIn = willChangeTextIn
            self.didChangeTextIn = didChangeTextIn
        }

        func textViewWillChangeText(_ notification: Notification) {
            willChangeText(notification)
        }

        func textViewDidChangeText(_ notification: Notification) {
            didChangeText(notification)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            didChangeSelection(notification)
        }

        func textView(_: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
            willChangeTextIn(affectedCharRange, replacementString)
        }

        func textView(_: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
            shouldChangeTextIn(affectedCharRange, replacementString)
        }

        func textView(_: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
            didChangeTextIn(affectedCharRange, replacementString)
        }
    }

#endif
