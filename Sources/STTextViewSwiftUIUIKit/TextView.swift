//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import UIKit
import STTextView

/// This SwiftUI view can be used to view and edit rich text.
@MainActor @preconcurrency
public struct TextView: SwiftUI.View, TextViewModifier {

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

        /// Enable to show line numbers in the gutter.
        public static let showLineNumbers = Options(rawValue: 1 << 2)
    }

    @Environment(\.colorScheme) private var colorScheme
    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?
    private let options: Options
    private let plugins: [any STPlugin]

    /// Create a text edit view with a certain text that uses a certain options.
    /// - Parameters:
    ///   - text: The attributed string content
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

private struct TextViewRepresentable: UIViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.font) private var font
    @Environment(\.lineSpacing) private var lineSpacing

    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?
    private let options: TextView.Options
    private var plugins: [any STPlugin]

    init(text: Binding<AttributedString>, selection: Binding<NSRange?>, options: TextView.Options, plugins: [any STPlugin] = []) {
        self._text = text
        self._selection = selection
        self.options = options
        self.plugins = plugins
    }

    func makeUIView(context: Context) -> STTextView {
        let textView = STTextView()
        textView.textDelegate = context.coordinator
        textView.highlightSelectedLine = options.contains(.highlightSelectedLine)
        textView.isHorizontallyResizable = !options.contains(.wrapLines)
        textView.showsLineNumbers = options.contains(.showLineNumbers)

        context.coordinator.isUpdating = true
        textView.attributedText = NSAttributedString(styledAttributedString(textView.typingAttributes))
        context.coordinator.isUpdating = false

        //for plugin in plugins {
        //    textView.addPlugin(plugin)
        //}

        return textView
    }

    func updateUIView(_ textView: STTextView, context: Context) {
        context.coordinator.parent = self

        do {
            context.coordinator.isUpdating = true
            if context.coordinator.isDidChangeText == false {
                textView.attributedText = NSAttributedString(styledAttributedString(textView.typingAttributes))
            }
            context.coordinator.isUpdating = false
            context.coordinator.isDidChangeText = false
        }

//        if textView.selectedRange() != selection, let selection {
//            textView.setSelectedRange(selection)
//            textView.setNeedsLayout()
//        }

        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
            textView.setNeedsLayout()
        }

        if textView.isSelectable != isEnabled {
            textView.isSelectable = isEnabled
            textView.setNeedsLayout()
        }

        if textView.font != font {
            textView.font = font
            textView.setNeedsLayout()
        }

        if options.contains(.wrapLines) != textView.isHorizontallyResizable {
            textView.isHorizontallyResizable = !options.contains(.wrapLines)
            textView.setNeedsLayout()
        }

        textView.layoutIfNeeded()
    }

    func makeCoordinator() -> TextCoordinator {
        TextCoordinator(parent: self)
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
                let newTextValue = AttributedString(textView.attributedText ?? NSAttributedString())
                DispatchQueue.main.async {
                    self.isDidChangeText = true
                    self.parent.text = newTextValue
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? STTextView else {
                return
            }

            Task { @MainActor in
                self.isDidChangeText = true
                self.parent.selection = textView.textSelection
            }
        }

    }
}

