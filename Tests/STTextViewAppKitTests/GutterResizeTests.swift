#if os(macOS)
import XCTest
@testable import STTextViewAppKit

/// Reproduction test for gutter row collapse during window resize.
///
/// Creates an STTextView with a custom gutter data source, positions it inside
/// an NSScrollView in a real window, then programmatically resizes the window.
/// After each resize step, inspects the gutter line view Y positions to check
/// whether they remain distinct and increasing (correct) or all collapse to
/// the same value (the bug).
@MainActor
final class GutterResizeTests: XCTestCase {

    /// Simple data source that creates plain NSView labels for each gutter line.
    /// Uses NSTextField (lightweight) rather than NSHostingView to isolate whether
    /// the bug is in the gutter layout code or in NSHostingView specifically.
    private final class SimpleGutterDataSource: STGutterLineViewDataSource {
        func textView(_ textView: STTextView, viewForGutterLine lineNumber: Int, content: String) -> NSView {
            let label = NSTextField(labelWithString: "\(lineNumber)")
            label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            return label
        }

        func textView(_ textView: STTextView, updateView existingView: NSView, forGutterLine lineNumber: Int, content: String) -> Bool {
            guard let label = existingView as? NSTextField else { return false }
            label.stringValue = "\(lineNumber)"
            return true
        }
    }

    /// Same as above but using NSHostingView (matches real usage in lyrics app).
    private final class HostingGutterDataSource: STGutterLineViewDataSource {
        func textView(_ textView: STTextView, viewForGutterLine lineNumber: Int, content: String) -> NSView {
            // Import SwiftUI only if available
            let label = NSTextField(labelWithString: "H\(lineNumber)")
            label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            return label
        }

        func textView(_ textView: STTextView, updateView existingView: NSView, forGutterLine lineNumber: Int, content: String) -> Bool {
            guard let label = existingView as? NSTextField else { return false }
            label.stringValue = "H\(lineNumber)"
            return true
        }
    }

    // MARK: - Helpers

    /// Creates a text view with custom gutter inside a real window.
    /// Returns (window, scrollView, textView, dataSource).
    private func makeGutteredTextView(
        lineCount: Int = 20,
        gutterWidth: CGFloat = 64
    ) -> (NSWindow, NSScrollView, STTextView, SimpleGutterDataSource) {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        scrollView.automaticallyAdjustsContentInsets = false

        // Insert multi-line content
        let lines = (1...lineCount).map { "Line \($0) — some text content here" }
        let text = lines.joined(separator: "\n")
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.textColor
        ]
        textView.attributedText = NSAttributedString(string: text, attributes: attrs)

        // Configure custom gutter
        let dataSource = SimpleGutterDataSource()
        textView.customGutterWidth = gutterWidth
        textView.gutterLineViewDataSource = dataSource

        // Place in a real window so AppKit layout works
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
            styleMask: [.titled, .resizable, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        window.makeKeyAndOrderFront(nil)

        // Force initial layout
        textView.needsLayout = true
        textView.layoutSubtreeIfNeeded()

        return (window, scrollView, textView, dataSource)
    }

    /// Returns Y positions of all custom gutter line views in the container.
    private func gutterLineViewYPositions(in textView: STTextView) -> [CGFloat] {
        guard let container = textView.customGutterContainerView else { return [] }
        return container.subviews
            .filter { ($0.identifier?.rawValue ?? "").hasPrefix("stgutter-line-") }
            .sorted { $0.frame.origin.y < $1.frame.origin.y }
            .map { $0.frame.origin.y }
    }

    /// Returns identifiers and frames of all custom gutter line views.
    private func gutterLineViewInfo(in textView: STTextView) -> [(id: String, frame: NSRect)] {
        guard let container = textView.customGutterContainerView else { return [] }
        return container.subviews
            .compactMap { view -> (String, NSRect)? in
                guard let id = view.identifier?.rawValue, id.hasPrefix("stgutter-line-") else { return nil }
                return (id, view.frame)
            }
            .sorted { $0.0 < $1.0 }
    }

    // MARK: - Tests

    /// Verifies that gutter line views have distinct, increasing Y positions
    /// after initial layout.
    func testInitialGutterPositionsAreDistinct() throws {
        let (window, _, textView, _) = makeGutteredTextView()
        defer { window.close() }

        let positions = gutterLineViewYPositions(in: textView)
        XCTAssertGreaterThan(positions.count, 1, "Should have multiple gutter line views")

        // Verify all Y positions are distinct
        let unique = Set(positions)
        XCTAssertEqual(positions.count, unique.count,
                       "All gutter line views should have distinct Y positions. Got: \(positions)")

        // Verify Y positions are strictly increasing
        for i in 1..<positions.count {
            XCTAssertGreaterThan(positions[i], positions[i - 1],
                                 "Y positions should be strictly increasing. Index \(i): \(positions[i]) <= \(positions[i-1])")
        }
    }

    /// Core reproduction test: resizes the window multiple times and checks
    /// gutter line view positions after each resize.
    func testGutterPositionsRemainDistinctDuringResize() throws {
        let (window, _, textView, _) = makeGutteredTextView()
        defer { window.close() }

        // Verify initial state
        let initial = gutterLineViewYPositions(in: textView)
        XCTAssertGreaterThan(initial.count, 1, "Should have multiple gutter line views initially")

        // Simulate a resize sequence (wider, then narrower, then taller, then shorter)
        let resizeSizes: [NSSize] = [
            NSSize(width: 800, height: 400),  // wider
            NSSize(width: 400, height: 400),  // narrower
            NSSize(width: 600, height: 600),  // taller
            NSSize(width: 600, height: 300),  // shorter
            NSSize(width: 500, height: 500),  // medium
        ]

        for (index, size) in resizeSizes.enumerated() {
            // Simulate viewWillStartLiveResize
            textView.viewWillStartLiveResize()

            // Resize the window
            window.setContentSize(size)

            // Force layout (as AppKit would during resize)
            textView.needsLayout = true
            textView.layoutSubtreeIfNeeded()

            // Check gutter positions
            let positions = gutterLineViewYPositions(in: textView)
            let info = gutterLineViewInfo(in: textView)

            XCTAssertGreaterThan(positions.count, 0,
                                 "Step \(index) (size: \(size)): Should have gutter line views")

            // Check for the collapse bug: all views at same Y
            let uniqueY = Set(positions)
            XCTAssertEqual(positions.count, uniqueY.count,
                           "Step \(index) (size: \(size)): All gutter line views should have distinct Y positions.\n" +
                           "Positions: \(positions)\n" +
                           "Details: \(info.map { "\($0.id): y=\($0.frame.origin.y) h=\($0.frame.height)" }.joined(separator: "\n"))")

            // Check strictly increasing
            for i in 1..<positions.count {
                XCTAssertGreaterThan(positions[i], positions[i - 1],
                                     "Step \(index): Y[\(i)] (\(positions[i])) should be > Y[\(i-1)] (\(positions[i-1]))")
            }

            // End live resize
            textView.viewDidEndLiveResize()

            // Force layout again after end
            textView.needsLayout = true
            textView.layoutSubtreeIfNeeded()

            // Check positions again after live resize ends
            let postPositions = gutterLineViewYPositions(in: textView)
            let postUnique = Set(postPositions)
            XCTAssertEqual(postPositions.count, postUnique.count,
                           "Step \(index) post-resize: Gutter positions should still be distinct.\n" +
                           "Positions: \(postPositions)")
        }
    }

    /// Tests rapid sequential resizes without waiting (simulates dragging window edge).
    func testRapidResizeSequence() throws {
        let (window, _, textView, _) = makeGutteredTextView()
        defer { window.close() }

        textView.viewWillStartLiveResize()

        // Simulate rapid resize: 20 steps from 400 to 800 width
        for step in 0..<20 {
            let width = 400.0 + Double(step) * 20.0
            window.setContentSize(NSSize(width: width, height: 500))
            textView.needsLayout = true
            textView.layoutSubtreeIfNeeded()

            let positions = gutterLineViewYPositions(in: textView)
            if positions.count > 1 {
                let uniqueY = Set(positions)
                XCTAssertEqual(positions.count, uniqueY.count,
                               "Rapid step \(step) (width: \(width)): Positions collapsed! \(positions)")
            }
        }

        textView.viewDidEndLiveResize()
        textView.needsLayout = true
        textView.layoutSubtreeIfNeeded()

        let finalPositions = gutterLineViewYPositions(in: textView)
        let finalUnique = Set(finalPositions)
        XCTAssertGreaterThan(finalPositions.count, 1, "Should have gutter views after resize")
        XCTAssertEqual(finalPositions.count, finalUnique.count,
                       "Final positions should be distinct: \(finalPositions)")
    }

    /// Diagnostic test: prints detailed gutter state during resize for analysis.
    /// Not a pass/fail test — run with `-v` flag and inspect output.
    func testDiagnosticResizeLog() throws {
        let (window, scrollView, textView, _) = makeGutteredTextView(lineCount: 10)
        defer { window.close() }

        print("=== INITIAL STATE ===")
        print("Window: \(window.frame)")
        print("ScrollView: \(scrollView.frame)")
        print("TextViewFrame: \(textView.frame)")
        print("ContentViewFrame: \(textView.contentView.frame)")
        print("Container: \(textView.customGutterContainerView?.frame ?? .zero)")
        print("InLiveResize: \(textView.inLiveResize)")
        let info = gutterLineViewInfo(in: textView)
        for item in info {
            print("  \(item.id): frame=\(NSStringFromRect(item.frame))")
        }

        // Fragment view positions
        let viewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange
        print("ViewportRange: \(viewportRange?.description ?? "nil")")

        // Simulate resize
        print("\n=== RESIZE TO 800x400 ===")
        textView.viewWillStartLiveResize()
        window.setContentSize(NSSize(width: 800, height: 400))
        textView.needsLayout = true
        textView.layoutSubtreeIfNeeded()

        print("TextViewFrame: \(textView.frame)")
        print("Container: \(textView.customGutterContainerView?.frame ?? .zero)")
        print("InLiveResize: \(textView.inLiveResize)")
        let resizedInfo = gutterLineViewInfo(in: textView)
        for item in resizedInfo {
            print("  \(item.id): frame=\(NSStringFromRect(item.frame))")
        }

        textView.viewDidEndLiveResize()
        textView.needsLayout = true
        textView.layoutSubtreeIfNeeded()

        print("\n=== AFTER END LIVE RESIZE ===")
        print("TextViewFrame: \(textView.frame)")
        let postInfo = gutterLineViewInfo(in: textView)
        for item in postInfo {
            print("  \(item.id): frame=\(NSStringFromRect(item.frame))")
        }
    }
}
#endif
