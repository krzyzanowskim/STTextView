//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import STTextView

/// This SwiftUI view can be used to view and edit rich text.
public struct TextView: SwiftUI.View {

    @frozen
    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Breaks the text as needed to fit within the bounding box.
        public static let wrapLines = Options(rawValue: 1 << 0)

        /// Highlighted selected line
        public static let highlightSelectedLine = Options(rawValue: 1 << 1)
    }

    @Environment(\.colorScheme) private var colorScheme
    @Binding private var text: AttributedString
    private let options: Options

    /// Create a text edit view with a certain text that uses a certain options.
    /// - Parameters:
    ///   - text: The attributed string content
    ///   - options: Editor options
    public init(
        text: Binding<AttributedString>,
        options: Options = []
    ) {
        _text = text
        self.options = options
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            options: options
        )
        .background(.background)
    }
}

private struct TextViewRepresentable: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.font) private var font
    @Environment(\.lineSpacing) private var lineSpacing

    @Binding private var text: AttributedString
    private let options: TextView.Options

    init(text: Binding<AttributedString>, options: TextView.Options) {
        self._text = text
        self.options = options
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        textView.delegate = context.coordinator
        textView.highlightSelectedLine = options.contains(.highlightSelectedLine)
        textView.widthTracksTextView = options.contains(.wrapLines)
        textView.setSelectedRange(NSRange())

        textView.setAttributedString(NSAttributedString(styledAttributedString(textView.typingAttributes)))

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        let textView = scrollView.documentView as! STTextView

        do {
            context.coordinator.isUpdating = true
            if context.coordinator.isDidChangeText  == false {
                textView.setAttributedString(NSAttributedString(styledAttributedString(textView.typingAttributes)))
            }
            context.coordinator.isUpdating = false
            context.coordinator.isDidChangeText  = false
        }

        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
        }

        if textView.isSelectable != isEnabled {
            textView.isSelectable = isEnabled
        }

        let wrapLines = options.contains(.wrapLines)
        if wrapLines != textView.widthTracksTextView {
            textView.widthTracksTextView = options.contains(.wrapLines)
        }

        if textView.font != font {
            textView.font = font
        }
    }

    func makeCoordinator() -> TextCoordinator {
        TextCoordinator(parent: self)
    }

    private func styledAttributedString(_ typingAttributes: [NSAttributedString.Key: Any]) -> AttributedString {
        let paragraph = (typingAttributes[.paragraphStyle] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
        if !paragraph.lineSpacing.isAlmostEqual(to: lineSpacing) {
            paragraph.lineSpacing = lineSpacing
            var typingAttributes = typingAttributes
            typingAttributes[.paragraphStyle] = paragraph

            let attributeContainer = AttributeContainer(typingAttributes)
            var styledText = text
            styledText.mergeAttributes(attributeContainer, mergePolicy: .keepNew)
            return styledText
        }

        return text
    }

    class TextCoordinator: STTextViewDelegate {
        var parent: TextViewRepresentable
        var isUpdating: Bool = false
        var isDidChangeText: Bool = false
        var enqueuedValue: AttributedString?

        init(parent: TextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? STTextView else {
                return
            }

            if !isUpdating {
                let newTextValue = AttributedString(textView.attributedString())
                DispatchQueue.main.async {
                    self.isDidChangeText = true
                    self.parent.text = newTextValue
                }
            }
        }

    }
}

