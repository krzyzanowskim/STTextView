#if os(macOS)
    import AppKit
    import XCTest
    @testable import STTextViewAppKit

    @MainActor
    final class CompletionTests: XCTestCase {

        func testAsyncCompletionResultIsPresentedWhenRequestIsStillValid() async {
            let fixture = makeCompletionFixture()
            let item = TestCompletionItem()
            fixture.textView.text = "abc"
            fixture.textView.setSelectedRange(NSRange(location: 3, length: 0))

            fixture.textView.complete(nil)
            await fulfillment(of: [fixture.delegate.didRequestCompletion], timeout: 1)

            fixture.delegate.finishCompletion(with: [item])
            await Task.yield()

            XCTAssertEqual(fixture.completionViewController.items.count, 1)
            XCTAssertEqual(fixture.completionViewController.items.first?.id as? UUID, item.id)
        }

        func testAsyncCompletionResultIsDiscardedAfterTextChange() async {
            let fixture = makeCompletionFixture()
            fixture.textView.text = "abc"
            fixture.textView.setSelectedRange(NSRange(location: 3, length: 0))

            fixture.textView.complete(nil)
            await fulfillment(of: [fixture.delegate.didRequestCompletion], timeout: 1)

            fixture.textView.replaceCharacters(in: NSRange(location: 3, length: 0), with: "d")
            fixture.delegate.finishCompletion(with: [TestCompletionItem()])
            await Task.yield()

            XCTAssertTrue(fixture.completionViewController.items.isEmpty)
        }

        func testAsyncCompletionResultIsDiscardedAfterSelectionChange() async {
            let fixture = makeCompletionFixture()
            fixture.textView.text = "abc"
            fixture.textView.setSelectedRange(NSRange(location: 3, length: 0))

            fixture.textView.complete(nil)
            await fulfillment(of: [fixture.delegate.didRequestCompletion], timeout: 1)

            fixture.textView.shouldDimissCompletionOnSelectionChange = false
            fixture.textView.setSelectedRange(NSRange(location: 1, length: 0))
            fixture.delegate.finishCompletion(with: [TestCompletionItem()])
            await Task.yield()

            XCTAssertTrue(fixture.completionViewController.items.isEmpty)
        }

        private func makeCompletionFixture() -> CompletionFixture {
            let textView = STTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 120))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.contentView = textView

            let completionViewController = TestCompletionViewController()
            let delegate = AsyncCompletionDelegate(completionViewController: completionViewController)
            textView.textDelegate = delegate

            textView.layoutSubtreeIfNeeded()

            return CompletionFixture(
                window: window,
                textView: textView,
                delegate: delegate,
                completionViewController: completionViewController
            )
        }
    }

    private struct CompletionFixture {
        let window: NSWindow
        let textView: STTextView
        let delegate: AsyncCompletionDelegate
        let completionViewController: TestCompletionViewController
    }

    private final class AsyncCompletionDelegate: STTextViewDelegate {
        let didRequestCompletion = XCTestExpectation(description: "async completion requested")

        private let completionViewController: TestCompletionViewController
        private var continuation: CheckedContinuation<[any STCompletionItem]?, Never>?

        init(completionViewController: TestCompletionViewController) {
            self.completionViewController = completionViewController
        }

        func textView(_ textView: STTextView, completionItemsAtLocation location: any NSTextLocation) async -> [any STCompletionItem]? {
            didRequestCompletion.fulfill()

            return await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }

        func textViewCompletionViewController(_ textView: STTextView) -> any STCompletionViewControllerProtocol {
            completionViewController
        }

        func finishCompletion(with items: [any STCompletionItem]) {
            continuation?.resume(returning: items)
            continuation = nil
        }
    }

    private final class TestCompletionViewController: NSViewController, STCompletionViewControllerProtocol {
        weak var delegate: STCompletionViewControllerDelegate?
        var items: [any STCompletionItem] = []
    }

    private struct TestCompletionItem: STCompletionItem {
        let id = UUID()
        let view = NSView()
    }
#endif
