import Cocoa
import STTextView
import Neon

class STTextViewSystemInterface: TextSystemInterface {

    typealias AttributeProvider = (Neon.Token) -> [NSAttributedString.Key: Any]?

    private let textView: STTextView
    private let attributeProvider: AttributeProvider

    init(textView: STTextView, attributeProvider: @escaping AttributeProvider) {
        self.textView = textView
        self.attributeProvider = attributeProvider
    }

    func clearStyle(in range: NSRange) {
        textView.removeAttribute(.foregroundColor, range: range)
    }

    func applyStyle(to token: Neon.Token) {
        guard let attrs = attributeProvider(token) else { return }
        textView.addAttributes(attrs, range: token.range)
    }

    var length: Int {
        (textView.textContentManager as! NSTextContentStorage).textStorage?.length ?? 0
    }

    var visibleRange: NSRange {
        guard let viewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange else {
            return .zero
        }

        return NSRange(viewportRange, provider: textView.textContentManager)
    }
}
