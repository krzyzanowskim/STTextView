//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import STTextView
import STTextViewSwiftUICommon

/// A SwiftUI view for viewing and editing rich text.
@MainActor @preconcurrency
public struct TextView: SwiftUI.View, TextViewModifier {

    public typealias Options = TextViewOptions

    // Triggers re-render on appearance changes
    @Environment(\.colorScheme) private var colorScheme

    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?
    private let options: Options
    private let plugins: [any STPlugin]

    /// Create a text edit view with a certain text that uses a certain options.
    /// - Parameters:
    ///   - text: The attributed string content
    ///   - selection: The current selection range
    ///   - options: Editor options
    ///   - plugins: Editor plugins
    public init(
        text: Binding<AttributedString>,
        selection: Binding<NSRange?> = .constant(nil),
        options: Options = [],
        plugins: [any STPlugin] = []
    ) {
        _text = text
        _selection = selection
        self.options = options
        self.plugins = plugins
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection,
            options: options,
            plugins: plugins
        )
        .background(.background)
    }
}

private struct TextViewRepresentable: NSViewRepresentable {
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.font)
    private var font
    @Environment(\.lineSpacing)
    private var lineSpacing
    @Environment(\.lineHeightMultiple)
    private var lineHeightMultiple
    @Environment(\.autocorrectionDisabled)
    private var autocorrectionDisabled

    @Binding
    private var text: AttributedString
    @Binding
    private var selection: NSRange?
    private let options: TextView.Options
    private var plugins: [any STPlugin]

    init(text: Binding<AttributedString>, selection: Binding<NSRange?>, options: TextView.Options, plugins: [any STPlugin] = []) {
        self._text = text
        self._selection = selection
        self.options = options
        self.plugins = plugins
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        textView.textDelegate = context.coordinator
        textView.highlightSelectedLine = options.contains(.highlightSelectedLine)
        textView.isHorizontallyResizable = !options.contains(.wrapLines)
        textView.showsLineNumbers = options.contains(.showLineNumbers)
        textView.textSelection = NSRange()

        if lineHeightMultiple != 1.0 {
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineHeightMultiple = lineHeightMultiple
            textView.defaultParagraphStyle = paragraphStyle
        }

        textView.isAutomaticSpellingCorrectionEnabled = !autocorrectionDisabled
        if options.contains(.disableSmartQuotes) {
            textView.isAutomaticQuoteSubstitutionEnabled = false
        }
        if options.contains(.disableTextReplacement) {
            textView.isAutomaticTextReplacementEnabled = false
        }
        if options.contains(.disableTextCompletion) {
            textView.isAutomaticTextCompletionEnabled = false
        }

        if options.contains(.showLineNumbers) {
            textView.gutterView?.font = textView.font
            textView.gutterView?.textColor = .secondaryLabelColor
        }

        context.coordinator.isUpdating = true
        textView.attributedText = NSAttributedString(styledAttributedString(textView.typingAttributes))
        context.coordinator.isUpdating = false

        for plugin in plugins {
            textView.addPlugin(plugin)
        }

        context.coordinator.lastFont = textView.font

        textView.isEditable = isEnabled
        textView.isSelectable = isEnabled

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! STTextView

        if !context.coordinator.isUserEditing {
            context.coordinator.isUpdating = true
            textView.attributedText = NSAttributedString(styledAttributedString(textView.typingAttributes))
            context.coordinator.isUpdating = false
        }
        context.coordinator.isUserEditing = false

        if textView.textSelection != selection, let selection {
            textView.textSelection = selection
        }

        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
        }

        if textView.isSelectable != isEnabled {
            textView.isSelectable = isEnabled
        }

        if font != context.coordinator.lastFont {
            context.coordinator.lastFont = font
            textView.font = font
            textView.gutterView?.font = font
        }

        if textView.isAutomaticSpellingCorrectionEnabled == autocorrectionDisabled {
            textView.isAutomaticSpellingCorrectionEnabled = !autocorrectionDisabled
        }

        if options.contains(.wrapLines) == textView.isHorizontallyResizable {
            textView.isHorizontallyResizable = !options.contains(.wrapLines)
        }

        if textView.showsLineNumbers != options.contains(.showLineNumbers) {
            textView.showsLineNumbers = options.contains(.showLineNumbers)
            if options.contains(.showLineNumbers) {
                textView.gutterView?.font = textView.font
                textView.gutterView?.textColor = .secondaryLabelColor
            }
        }

        textView.needsLayout = true
        textView.needsDisplay = true
    }

    func makeCoordinator() -> TextCoordinator {
        TextCoordinator(text: $text, selection: $selection)
    }

    private func styledAttributedString(_ typingAttributes: [NSAttributedString.Key: Any]) -> AttributedString {
        let paragraph = (typingAttributes[.paragraphStyle] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
        if paragraph.lineSpacing != lineSpacing {
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
        @Binding var text: AttributedString
        @Binding var selection: NSRange?
        var isUpdating = false
        var isUserEditing = false
        var lastFont: NSFont?

        init(text: Binding<AttributedString>, selection: Binding<NSRange?>) {
            self._text = text
            self._selection = selection
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? STTextView else {
                return
            }
            isUserEditing = true
            text = AttributedString(textView.attributedText ?? NSAttributedString())
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? STTextView else {
                return
            }

            selection = textView.selectedRange()
        }

    }
}

