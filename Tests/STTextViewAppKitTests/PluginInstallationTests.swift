import XCTest
@testable import STTextViewAppKit

final class PluginInstallationTests: XCTestCase {
    final class Counter: @unchecked Sendable {
        var setUps = 0
        var tearDowns = 0
    }

    struct ValuePlugin: STPlugin {
        let counter: Counter
        func setUp(context: any Context) { counter.setUps += 1 }
        func tearDown() { counter.tearDowns += 1 }
    }

    final class ReferencePlugin: STPlugin {
        let counter: Counter
        init(counter: Counter) { self.counter = counter }
        func setUp(context: any Context) { counter.setUps += 1 }
        func tearDown() { counter.tearDowns += 1 }
    }

    @MainActor
    private func makeTextView() -> STTextView {
        let textView = STTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        let window = NSWindow(contentRect: textView.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = textView
        return textView
    }

    @MainActor
    func testIdentityComesFromTheIdArgument() {
        // The id passed to addPlugin is the only source of an installation's
        // identity, and is always honoured.
        let textView = makeTextView()
        let counter = Counter()
        let plugin = ReferencePlugin(counter: counter)

        let a = textView.addPlugin(plugin, id: STPluginIdentifier("a"))
        let b = textView.addPlugin(plugin, id: STPluginIdentifier("b"))

        XCTAssertEqual(a, STPluginIdentifier("a"))
        XCTAssertEqual(b, STPluginIdentifier("b"))
        XCTAssertEqual(textView.plugins.map(\.id), [a, b])
    }

    @MainActor
    func testRemovingOneInstallationLeavesTheOther() {
        let textView = makeTextView()
        let counter = Counter()
        let plugin = ValuePlugin(counter: counter)

        let first = textView.addPlugin(plugin)
        let second = textView.addPlugin(plugin)
        textView.removePlugin(first)

        XCTAssertEqual(textView.plugins.map(\.id), [second])
        XCTAssertEqual(counter.tearDowns, 1)
    }

    @MainActor
    func testDistinctReferencePluginsInstallSeparately() {
        let textView = makeTextView()
        let counter = Counter()

        let first = textView.addPlugin(ReferencePlugin(counter: counter))
        let second = textView.addPlugin(ReferencePlugin(counter: counter))

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(textView.plugins.count, 2)
        XCTAssertEqual(counter.setUps, 2)
    }

    @MainActor
    func testValuePluginsInstallIndependently() {
        // Value plugins are copied on install, so repeated installs are distinct.
        let textView = makeTextView()
        let counter = Counter()
        let plugin = ValuePlugin(counter: counter)

        let first = textView.addPlugin(plugin)
        let second = textView.addPlugin(plugin)

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(textView.plugins.count, 2)
        XCTAssertEqual(counter.setUps, 2)
    }

    @MainActor
    func testNamedIdentifierIsStableAcrossInstalls() {
        let textView = makeTextView()
        let counter = Counter()
        let slot = STPluginIdentifier("slot")

        textView.addPlugin(ValuePlugin(counter: counter), id: slot)
        textView.removePlugin(slot)
        textView.addPlugin(ValuePlugin(counter: counter), id: slot)

        XCTAssertEqual(textView.plugins.count, 1)
        XCTAssertEqual(counter.setUps, 2)
        XCTAssertEqual(counter.tearDowns, 1)
    }

    @MainActor
    func testRemovingSharedIdentifierRemovesAllInstallations() {
        let textView = makeTextView()
        let counter = Counter()
        let slot = STPluginIdentifier("slot")

        textView.addPlugin(ValuePlugin(counter: counter), id: slot)
        textView.addPlugin(ValuePlugin(counter: counter), id: slot)
        textView.removePlugin(slot)

        XCTAssertTrue(textView.plugins.isEmpty, "no installation may be left unreachable")
        XCTAssertEqual(counter.tearDowns, 2)
    }
}
