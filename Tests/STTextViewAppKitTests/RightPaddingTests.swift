import AppKit
import Testing
@testable import STTextViewAppKit

@Suite("rightPadding behavior")
@MainActor
struct RightPaddingTests {

  @Test("defaults to zero")
  func defaultsToZero() {
    let textView = STTextView()
    #expect(textView.rightPadding == 0)
  }

  @Test("included in frame width after layout")
  func includedInFrameWidth() {
    let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
    textView.text = "Hello, world"
    textView.layout()
    let widthWithoutPadding = textView.frame.width

    textView.rightPadding = 280
    textView.layout()
    let widthWithPadding = textView.frame.width

    #expect(abs(widthWithPadding - (widthWithoutPadding + 280)) < 1.0)
  }

  @Test("rightPadding and bottomPadding can be combined")
  func combinedPaddings() {
    let textView = STTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
    textView.text = "Line 1\nLine 2"
    textView.layout()
    let originalWidth = textView.frame.width
    let originalHeight = textView.frame.height

    textView.rightPadding = 200
    textView.bottomPadding = 100
    textView.layout()

    #expect(abs(textView.frame.width - (originalWidth + 200)) < 1.0)
    #expect(abs(textView.frame.height - (originalHeight + 100)) < 1.0)
  }
}
