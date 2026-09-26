#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    @MainActor
    final class GutterMarkerTests: XCTestCase {

        private final class GutterDelegate: STGutterViewDelegate {
            var changeCount = 0

            func textViewGutterDidChangeMarkers(_ gutter: STGutterView) {
                changeCount += 1
            }
        }

        // Line k starts at offset 2 * (k - 1)
        private func makeTextView(markers: [Int], text: String = "1\n2\n3\n4\n5\n") throws -> (STTextView, STGutterView) {
            let textView = STTextView()
            textView.text = text
            textView.showsLineNumbers = true
            let gutterView = try XCTUnwrap(textView.gutterView)
            for lineNumber in markers {
                gutterView.addMarker(STGutterMarker(lineNumber: lineNumber))
            }
            return (textView, gutterView)
        }

        func testInsertLineAboveShiftsMarker() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            textView.replaceCharacters(in: NSRange(location: 0, length: 0), with: "0\n")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [4])
        }

        func testInsertLineBelowKeepsMarker() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            textView.replaceCharacters(in: NSRange(location: 6, length: 0), with: "x\n")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [3])
        }

        func testNewlineAtStartOfMarkedLineMovesMarkerWithContent() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            textView.replaceCharacters(in: NSRange(location: 4, length: 0), with: "\n")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [4])
        }

        func testNewlineAtEndOfMarkedLineKeepsMarker() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            textView.replaceCharacters(in: NSRange(location: 5, length: 0), with: "\n")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [3])
        }

        func testDeletingMarkedLineRemovesMarkerAndShiftsNext() throws {
            let (textView, gutterView) = try makeTextView(markers: [3, 4])
            textView.replaceCharacters(in: NSRange(location: 4, length: 2), with: "")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [3])
            XCTAssertEqual(textView.text, "1\n2\n4\n5\n")
        }

        func testJoiningMarkedLinesKeepsMarkerOfUpperLine() throws {
            let (textView, gutterView) = try makeTextView(markers: [5, 4, 3])
            let upperLineView = try XCTUnwrap(gutterView.marker(lineNumber: 3)?.view)
            // Backspace at the start of line 4
            textView.replaceCharacters(in: NSRange(location: 5, length: 1), with: "")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber).sorted(), [3, 4])
            XCTAssertTrue(gutterView.marker(lineNumber: 3)?.view === upperLineView)
        }

        func testDeletingRangeAcrossLinesRemovesCoveredMarkers() throws {
            let (textView, gutterView) = try makeTextView(markers: [2, 3, 4, 5])
            // From the end of line 2 to the end of line 4
            textView.replaceCharacters(in: NSRange(location: 3, length: 4), with: "")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [2, 3])
        }

        func testReplacingLineContentKeepsMarker() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            textView.replaceCharacters(in: NSRange(location: 4, length: 1), with: "x")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [3])
        }

        func testCRLFLineBreaks() throws {
            let (textView, gutterView) = try makeTextView(markers: [3], text: "1\r\n2\r\n3\r\n")
            textView.replaceCharacters(in: NSRange(location: 0, length: 3), with: "")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [2])
        }

        func testDelegateNotifiedOnlyWhenMarkersChange() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            let delegate = GutterDelegate()
            gutterView.delegate = delegate

            textView.replaceCharacters(in: NSRange(location: 0, length: 0), with: "x")
            XCTAssertEqual(delegate.changeCount, 0)

            textView.replaceCharacters(in: NSRange(location: 0, length: 0), with: "\n")
            XCTAssertEqual(delegate.changeCount, 1)
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [4])
        }

        func testReplacingWholeDocumentKeepsMarkers() throws {
            let (textView, gutterView) = try makeTextView(markers: [3, 5])
            textView.text = "a\nb\n"
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [3, 5])
            textView.attributedText = NSAttributedString(string: "x\ny\nz\n")
            XCTAssertEqual(gutterView.markers.map(\.lineNumber), [3, 5])
        }

        func testMarkerKeepsViewWhenMoved() throws {
            let (textView, gutterView) = try makeTextView(markers: [3])
            let view = try XCTUnwrap(gutterView.markers.first?.view)
            textView.replaceCharacters(in: NSRange(location: 0, length: 0), with: "\n")
            XCTAssertTrue(gutterView.markers.first?.view === view)
        }
    }
#endif
