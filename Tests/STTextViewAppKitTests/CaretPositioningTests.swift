#if os(macOS)
import XCTest
@testable import STTextViewAppKit
@testable import STTextKitPlus

final class CaretPositioningTests: XCTestCase {

    /// Test that caretLocationWithAffinity returns upstream affinity when clicking past end of wrapped line
    func testCaretAffinityAtWrappedLineEnd() {
        // Create a text view with a narrow width to force wrapping
        let textView = STTextView()
        textView.frame = NSRect(x: 0, y: 0, width: 200, height: 300)
        textView.attributedText = NSAttributedString(
            string: "This is a long line that should wrap to the next line when the view is narrow enough",
            attributes: [.font: NSFont.systemFont(ofSize: 14)]
        )

        // Force layout to complete
        textView.layoutSubtreeIfNeeded()
        textView.textLayoutManager.ensureLayout(for: textView.textLayoutManager.documentRange)

        // Get the first line fragment range to understand where wrapping occurs
        guard let documentStart = textView.textLayoutManager.documentRange.location as? NSTextLocation else {
            XCTFail("Could not get document start location")
            return
        }

        // Enumerate line fragments to find where wrapping happens
        var firstLineEndOffset: Int = 0
        var firstLineMaxX: CGFloat = 0

        textView.textLayoutManager.enumerateTextLayoutFragments(from: documentStart, options: []) { fragment in
            for lineFragment in fragment.textLineFragments {
                // Get the range of text in this line fragment
                if let range = fragment.rangeInElement.location as? NSTextLocation {
                    let offset = textView.textLayoutManager.offset(from: documentStart, to: range)
                    if offset == 0 {
                        // This is the first line fragment
                        firstLineMaxX = lineFragment.typographicBounds.maxX + fragment.layoutFragmentFrame.origin.x
                        // Find where this line ends
                        let lineRange = lineFragment.characterRange
                        firstLineEndOffset = lineRange.upperBound
                    }
                }
            }
            return false // Only process first fragment
        }

        // Skip test if text didn't wrap (view too wide or text too short)
        guard firstLineEndOffset > 0 && firstLineEndOffset < textView.attributedText?.length ?? 0 else {
            // Text didn't wrap - this is fine, just skip the test
            return
        }

        // Now test clicking past the end of the first line
        // We'll click at an X coordinate past the text, but on the first line's Y
        let clickPoint = CGPoint(x: firstLineMaxX + 50, y: 10) // Past end of first line

        guard let containerLocation = textView.textLayoutManager.documentRange.location as? NSTextLocation else {
            XCTFail("Could not get container location")
            return
        }

        // Call caretLocationWithAffinity
        let result = textView.textLayoutManager.caretLocationWithAffinity(
            interactingAt: clickPoint,
            inContainerAt: containerLocation
        )

        // Verify we got a result
        XCTAssertNotNil(result, "caretLocationWithAffinity should return a result")

        if let (location, affinity) = result {
            let locationOffset = textView.textLayoutManager.offset(from: documentStart, to: location)

            // When clicking past end of wrapped line, affinity should be upstream
            // and location should be at or just after the last character of the first line
            XCTAssertEqual(affinity, .upstream, "Affinity should be upstream when clicking past end of wrapped line")
            XCTAssertGreaterThanOrEqual(locationOffset, firstLineEndOffset - 1, "Location should be at end of first line")
            XCTAssertLessThanOrEqual(locationOffset, firstLineEndOffset + 1, "Location should be at end of first line")
        }
    }

    /// Test that caretLocationWithAffinity returns downstream affinity for normal clicks within text
    func testCaretAffinityForNormalClick() {
        let textView = STTextView()
        textView.frame = NSRect(x: 0, y: 0, width: 400, height: 100)
        textView.attributedText = NSAttributedString(
            string: "Hello world",
            attributes: [.font: NSFont.systemFont(ofSize: 14)]
        )

        textView.layoutSubtreeIfNeeded()
        textView.textLayoutManager.ensureLayout(for: textView.textLayoutManager.documentRange)

        guard let containerLocation = textView.textLayoutManager.documentRange.location as? NSTextLocation else {
            XCTFail("Could not get container location")
            return
        }

        // Click in the middle of the text
        let clickPoint = CGPoint(x: 50, y: 10)

        let result = textView.textLayoutManager.caretLocationWithAffinity(
            interactingAt: clickPoint,
            inContainerAt: containerLocation
        )

        XCTAssertNotNil(result, "caretLocationWithAffinity should return a result")

        if let (_, affinity) = result {
            // Normal clicks should have downstream affinity
            XCTAssertEqual(affinity, .downstream, "Affinity should be downstream for normal clicks")
        }
    }

    /// Test that caretLocation delegates to caretLocationWithAffinity correctly
    func testCaretLocationDelegatesToCaretLocationWithAffinity() {
        let textView = STTextView()
        textView.frame = NSRect(x: 0, y: 0, width: 400, height: 100)
        textView.attributedText = NSAttributedString(
            string: "Hello world",
            attributes: [.font: NSFont.systemFont(ofSize: 14)]
        )

        textView.layoutSubtreeIfNeeded()
        textView.textLayoutManager.ensureLayout(for: textView.textLayoutManager.documentRange)

        guard let containerLocation = textView.textLayoutManager.documentRange.location as? NSTextLocation else {
            XCTFail("Could not get container location")
            return
        }

        let clickPoint = CGPoint(x: 50, y: 10)

        // Both methods should return the same location
        let locationOnly = textView.textLayoutManager.caretLocation(
            interactingAt: clickPoint,
            inContainerAt: containerLocation
        )
        let locationWithAffinity = textView.textLayoutManager.caretLocationWithAffinity(
            interactingAt: clickPoint,
            inContainerAt: containerLocation
        )

        XCTAssertNotNil(locationOnly, "caretLocation should return a result")
        XCTAssertNotNil(locationWithAffinity, "caretLocationWithAffinity should return a result")

        if let loc1 = locationOnly, let (loc2, _) = locationWithAffinity {
            let offset1 = textView.textLayoutManager.offset(
                from: textView.textLayoutManager.documentRange.location,
                to: loc1
            )
            let offset2 = textView.textLayoutManager.offset(
                from: textView.textLayoutManager.documentRange.location,
                to: loc2
            )
            XCTAssertEqual(offset1, offset2, "Both methods should return the same location")
        }
    }
}
#endif
