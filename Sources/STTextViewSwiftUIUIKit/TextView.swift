//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import UIKit
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
    private let contentInsets: EdgeInsets?

    /// Create a text edit view with a certain text that uses a certain options.
    /// - Parameters:
    ///   - text: The attributed string content
    ///   - selection: The current selection range
    ///   - options: Editor options
    ///   - plugins: Editor plugins
    ///   - contentInsets: Custom content insets. When provided, disables automatic safe area adjustment.
    public init(
        text: Binding<AttributedString>,
        selection: Binding<NSRange?> = .constant(nil),
        options: Options = [],
        plugins: [any STPlugin] = [],
        contentInsets: EdgeInsets? = nil
    ) {
        _text = text
        _selection = selection
        self.options = options
        self.plugins = plugins
        self.contentInsets = contentInsets
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection,
            options: options,
            plugins: plugins,
            contentInsets: contentInsets
        )
        .background(.background)
    }
}

private struct TextViewRepresentable: UIViewRepresentable {
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.editMode)
    private var editMode
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
    private let contentInsets: EdgeInsets?

    /// Resolved editable state: Only restrict editing when EditMode is explicitly active (in a List).
    /// When EditMode is inactive or not set, fall back to isEnabled.
    private var resolvedIsEditable: Bool {
        if let editMode = editMode?.wrappedValue, editMode.isEditing {
            // Only in active edit mode (e.g., List editing), follow the edit mode
            return true
        }
        // In all other cases (inactive, transient, or no edit mode), use isEnabled
        return isEnabled
    }

    init(text: Binding<AttributedString>, selection: Binding<NSRange?>, options: TextView.Options, plugins: [any STPlugin] = [], contentInsets: EdgeInsets? = nil) {
        self._text = text
        self._selection = selection
        self.options = options
        self.plugins = plugins
        self.contentInsets = contentInsets
    }

    func makeUIView(context: Context) -> STTextView {
        let textView = STTextView()
        textView.textDelegate = context.coordinator
        textView.highlightSelectedLine = options.contains(.highlightSelectedLine)
        textView.isHorizontallyResizable = !options.contains(.wrapLines)
        textView.showsLineNumbers = options.contains(.showLineNumbers)

        if lineHeightMultiple != 1.0 {
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineHeightMultiple = lineHeightMultiple
            textView.defaultParagraphStyle = paragraphStyle
        }

        textView.autocorrectionType = autocorrectionDisabled ? .no : .default
        if options.contains(.disableAutocapitalization) {
            textView.autocapitalizationType = .none
        }
        if options.contains(.disableSmartQuotes) {
            textView.smartQuotesType = .no
        }
        if options.contains(.disableSmartDashes) {
            textView.smartDashesType = .no
        }
        if options.contains(.disableSmartInsertDelete) {
            textView.smartInsertDeleteType = .no
        }

        if options.contains(.showLineNumbers) {
            textView.gutterView?.font = textView.font
            textView.gutterView?.textColor = .secondaryLabel
        }

        context.coordinator.isUpdating = true
        textView.attributedText = NSAttributedString(styledAttributedString(textView.typingAttributes))
        context.coordinator.isUpdating = false

        for plugin in plugins {
            textView.addPlugin(plugin)
        }

        if let contentInsets {
            textView.contentInsetAdjustmentBehavior = .never
            textView.contentInset = contentInsets.uiEdgeInsets(for: textView)
        }

        context.coordinator.lastFont = textView.font

        textView.isEditable = resolvedIsEditable
        textView.isSelectable = resolvedIsEditable

        return textView
    }

    func updateUIView(_ textView: STTextView, context: Context) {
        if !context.coordinator.isUserEditing {
            context.coordinator.isUpdating = true
            textView.attributedText = NSAttributedString(styledAttributedString(textView.typingAttributes))
            context.coordinator.isUpdating = false
        }
        context.coordinator.isUserEditing = false

        if textView.textSelection != selection, let selection {
            textView.textSelection = selection
        }

        if textView.isEditable != resolvedIsEditable {
            textView.isEditable = resolvedIsEditable
            textView.setNeedsLayout()
        }

        if textView.isSelectable != resolvedIsEditable {
            textView.isSelectable = resolvedIsEditable
            textView.setNeedsLayout()
        }

        if font != context.coordinator.lastFont {
            context.coordinator.lastFont = font
            textView.font = font
            textView.gutterView?.font = font
            textView.setNeedsLayout()
        }

        let expectedAutocorrectionType: UITextAutocorrectionType = autocorrectionDisabled ? .no : .default
        if textView.autocorrectionType != expectedAutocorrectionType {
            textView.autocorrectionType = expectedAutocorrectionType
        }

        if options.contains(.wrapLines) == textView.isHorizontallyResizable {
            textView.isHorizontallyResizable = !options.contains(.wrapLines)
            textView.setNeedsLayout()
        }

        if textView.showsLineNumbers != options.contains(.showLineNumbers) {
            textView.showsLineNumbers = options.contains(.showLineNumbers)
            if options.contains(.showLineNumbers) {
                textView.gutterView?.font = textView.font
                textView.gutterView?.textColor = .secondaryLabel
            }
            textView.setNeedsLayout()
        }

        if let contentInsets {
            textView.contentInset = contentInsets.uiEdgeInsets(for: textView)
        }

        textView.layoutIfNeeded()
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
        var lastFont: UIFont?

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

            selection = textView.textSelection
        }

    }
}

// MARK: - EdgeInsets to UIEdgeInsets Conversion

private extension EdgeInsets {
    /// Converts SwiftUI EdgeInsets to UIKit UIEdgeInsets, respecting layout direction.
    func uiEdgeInsets(for view: UIView) -> UIEdgeInsets {
        let layoutDirection = view.effectiveUserInterfaceLayoutDirection
        let left = (layoutDirection == .rightToLeft) ? trailing : leading
        let right = (layoutDirection == .rightToLeft) ? leading : trailing
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}

