#if os(macOS)
    import XCTest
    @testable import STTextViewAppKit

    @MainActor
    class CopyPasteTests: XCTestCase {

        private func pasteboard() -> NSPasteboard {
            NSPasteboard(name: .init(rawValue: "STTextViewTests-\(UUID().uuidString)"))
        }

        private func textView(text: String, textColor: NSColor) -> STTextView {
            let textView = STTextView()
            textView.textColor = textColor
            textView.text = text
            textView.selectAll(nil)
            return textView
        }

        private func rtfString(_ pboard: NSPasteboard) throws -> String {
            let data = try XCTUnwrap(pboard.data(forType: .rtf))
            return try XCTUnwrap(String(data: data, encoding: .utf8))
        }

        func testDefaultTextColorIsNotWrittenToPasteboard() throws {
            let textView = textView(text: "let x = 1", textColor: .white)
            let pboard = pasteboard()

            XCTAssertTrue(textView.writeSelection(to: pboard, types: [.rtf, .string]))

            let attributed = try XCTUnwrap(NSAttributedString(rtf: XCTUnwrap(pboard.data(forType: .rtf)), documentAttributes: nil))
            attributed.enumerateAttribute(.foregroundColor, in: attributed.range, options: []) { value, range, _ in
                XCTAssertNil(value, "default text color leaked into the pasteboard at \(range)")
            }
        }

        func testExplicitForegroundColorIsPreserved() throws {
            let textView = textView(text: "let x = 1", textColor: .white)
            let keyword = NSColor(srgbRed: 1, green: 0.37, blue: 0.64, alpha: 1)
            textView.addAttributes([.foregroundColor: keyword], range: NSRange(location: 0, length: 3))

            let pboard = pasteboard()
            XCTAssertTrue(textView.writeSelection(to: pboard, types: [.rtf, .string]))

            let attributed = try XCTUnwrap(NSAttributedString(rtf: XCTUnwrap(pboard.data(forType: .rtf)), documentAttributes: nil))
            let pasted = try XCTUnwrap(attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)
            let lhs = try XCTUnwrap(pasted.usingColorSpace(.sRGB))
            let rhs = try XCTUnwrap(keyword.usingColorSpace(.sRGB))
            XCTAssertEqual(lhs.redComponent, rhs.redComponent, accuracy: 0.01)
            XCTAssertEqual(lhs.greenComponent, rhs.greenComponent, accuracy: 0.01)
            XCTAssertEqual(lhs.blueComponent, rhs.blueComponent, accuracy: 0.01)

            XCTAssertNil(attributed.attribute(.foregroundColor, at: attributed.length - 1, effectiveRange: nil))
        }

        /// Xcode themes define the plain color as white at 85%.
        func testDefaultTextColorWithAlphaIsRecognized() throws {
            let textView = textView(text: "plain", textColor: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.85))
            let pboard = pasteboard()

            XCTAssertTrue(textView.writeSelection(to: pboard, types: [.rtf, .string]))

            let attributed = try XCTUnwrap(NSAttributedString(rtf: XCTUnwrap(pboard.data(forType: .rtf)), documentAttributes: nil))
            XCTAssertNil(attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil))
        }

        func testPlainTextFlavorIsUnchanged() throws {
            let textView = textView(text: "let x = 1", textColor: .white)
            let pboard = pasteboard()

            XCTAssertTrue(textView.writeSelection(to: pboard, types: [.rtf, .string]))
            XCTAssertEqual(pboard.string(forType: .string), "let x = 1")
        }
    }
#endif
