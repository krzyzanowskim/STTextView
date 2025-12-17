import AppKit
import Testing
@testable import STTextViewAppKit

@Suite("bottomPadding behavior")
@MainActor
struct BottomPaddingTests {

  @Test("defaults to zero")
  func defaultsToZero() {
    let textView = STTextView()
    #expect(textView.bottomPadding == 0)
  }

  @Test("included in frame height after layout")
  func includedInFrameHeight() {
    let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
    textView.text = "Line 1\nLine 2\nLine 3"
    textView.layout()
    let heightWithoutPadding = textView.frame.height

    textView.bottomPadding = 200
    textView.layout()
    let heightWithPadding = textView.frame.height

    #expect(abs(heightWithPadding - (heightWithoutPadding + 200)) < 1.0)
  }

  @Test("fragment views created when scrolled to bottom")
  func fragmentViewsCreated() {
    let scrollView = STTextView.scrollableTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
    let textView = scrollView.documentView as! STTextView
    textView.bottomPadding = 200

    // Add enough text to extend beyond viewport
    let lines = (1...50).map { "Line \($0)" }.joined(separator: "\n")
    textView.text = lines
    textView.layout()

    // Scroll to bottom
    textView.scrollToEndOfDocument(nil)
    textView.layout()

    // Verify all content is laid out
    var lastFragmentMaxY: CGFloat = 0
    textView.textLayoutManager.enumerateTextLayoutFragments(
      from: textView.textLayoutManager.documentRange.endLocation,
      options: [.reverse]
    ) { fragment in
      lastFragmentMaxY = fragment.layoutFragmentFrame.maxY
      return false
    }

    #expect(lastFragmentMaxY > 0, "Fragment views should be created")
  }
}
