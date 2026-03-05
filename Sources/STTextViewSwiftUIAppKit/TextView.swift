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

// MARK: - Text View With Custom Gutter

/// A SwiftUI text editor view with a custom per-line gutter.
///
/// Each visible line in the editor gets its own SwiftUI gutter view,
/// positioned to fill the full line height (including spacing).
/// The view builder receives the 1-based line number and the plain-text
/// content of that line.
///
/// Usage:
/// ```swift
/// TextViewWithGutter(
///     text: $text,
///     gutterWidth: 64,
///     gutterContent: { lineNumber, lineContent in
///         Text("\(lineNumber)")
///     }
/// )
/// .gutterBackground(NSColor.controlBackgroundColor)
/// .gutterSeparator(color: .separatorColor, width: 1)
/// ```
@MainActor @preconcurrency
public struct TextViewWithGutter<GutterContent: View>: SwiftUI.View, TextViewModifier {

    public typealias Options = TextViewOptions

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.gutterBackgroundColor) private var envGutterBackgroundColor
    @Environment(\.gutterSeparatorColor) private var envGutterSeparatorColor
    @Environment(\.gutterSeparatorWidth) private var envGutterSeparatorWidth

    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?
    private let options: Options
    private let plugins: [any STPlugin]
    private let gutterWidth: CGFloat
    private let gutterLineViewFactory: (Int, String) -> NSView

    /// Create a text editor with a custom per-line gutter.
    ///
    /// - Parameters:
    ///   - text: The attributed string content
    ///   - selection: The current selection range
    ///   - options: Editor options
    ///   - plugins: Editor plugins
    ///   - gutterWidth: Width reserved for the custom gutter area (in points)
    ///   - gutterContent: A view builder called for each visible line with `(lineNumber, lineContent)`
    public init(
        text: Binding<AttributedString>,
        selection: Binding<NSRange?> = .constant(nil),
        options: Options = [],
        plugins: [any STPlugin] = [],
        gutterWidth: CGFloat,
        @ViewBuilder gutterContent: @escaping (_ lineNumber: Int, _ lineContent: String) -> GutterContent
    ) {
        _text = text
        _selection = selection
        self.options = options
        self.plugins = plugins
        self.gutterWidth = gutterWidth
        self.gutterLineViewFactory = { lineNumber, lineContent in
            NSHostingView(rootView: gutterContent(lineNumber, lineContent))
        }
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection,
            options: options,
            plugins: plugins,
            gutterWidth: gutterWidth,
            gutterLineViewFactory: gutterLineViewFactory,
            gutterBackgroundColor: envGutterBackgroundColor,
            gutterSeparatorColor: envGutterSeparatorColor,
            gutterSeparatorWidth: envGutterSeparatorWidth
        )
        .background(.background)
    }
}

// MARK: - Gutter Style Modifiers

/// Environment key for custom gutter background color.
private struct GutterBackgroundColorKey: EnvironmentKey {
    static let defaultValue: NSColor? = nil
}

/// Environment key for custom gutter separator color.
private struct GutterSeparatorColorKey: EnvironmentKey {
    static let defaultValue: NSColor? = nil
}

/// Environment key for custom gutter separator width.
private struct GutterSeparatorWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 2
}

extension EnvironmentValues {
    var gutterBackgroundColor: NSColor? {
        get { self[GutterBackgroundColorKey.self] }
        set { self[GutterBackgroundColorKey.self] = newValue }
    }

    var gutterSeparatorColor: NSColor? {
        get { self[GutterSeparatorColorKey.self] }
        set { self[GutterSeparatorColorKey.self] = newValue }
    }

    var gutterSeparatorWidth: CGFloat {
        get { self[GutterSeparatorWidthKey.self] }
        set { self[GutterSeparatorWidthKey.self] = newValue }
    }
}

public extension TextViewModifier {

    /// Sets the background color for the custom gutter area.
    func gutterBackground(_ color: NSColor?) -> TextViewEnvironmentModifier<Self, NSColor?> {
        TextViewEnvironmentModifier(content: self, keyPath: \.gutterBackgroundColor, value: color)
    }

    /// Sets the trailing separator for the custom gutter area.
    /// - Parameters:
    ///   - color: Color of the vertical separator line (nil hides it)
    ///   - width: Width of the separator in points (default 2)
    func gutterSeparator(color: NSColor?, width: CGFloat = 2) -> TextViewEnvironmentModifier<TextViewEnvironmentModifier<Self, NSColor?>, CGFloat> {
        TextViewEnvironmentModifier(
            content: TextViewEnvironmentModifier(content: self, keyPath: \.gutterSeparatorColor, value: color),
            keyPath: \.gutterSeparatorWidth,
            value: width
        )
    }
}

// MARK: - NSViewRepresentable

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
    let gutterWidth: CGFloat
    let gutterLineViewFactory: ((Int, String) -> NSView)?
    let gutterBackgroundColor: NSColor?
    let gutterSeparatorColor: NSColor?
    let gutterSeparatorWidth: CGFloat

    init(text: Binding<AttributedString>, selection: Binding<NSRange?>, options: TextView.Options, plugins: [any STPlugin] = [], gutterWidth: CGFloat = 0, gutterLineViewFactory: ((Int, String) -> NSView)? = nil, gutterBackgroundColor: NSColor? = nil, gutterSeparatorColor: NSColor? = nil, gutterSeparatorWidth: CGFloat = 0) {
        self._text = text
        self._selection = selection
        self.options = options
        self.plugins = plugins
        self.gutterWidth = gutterWidth
        self.gutterLineViewFactory = gutterLineViewFactory
        self.gutterBackgroundColor = gutterBackgroundColor
        self.gutterSeparatorColor = gutterSeparatorColor
        self.gutterSeparatorWidth = gutterSeparatorWidth
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

        // Configure custom gutter if provided
        if gutterWidth > 0 {
            textView.customGutterWidth = gutterWidth
            textView.gutterLineViewProvider = gutterLineViewFactory
            textView.customGutterBackgroundColor = gutterBackgroundColor
            textView.customGutterSeparatorColor = gutterSeparatorColor
            textView.customGutterSeparatorWidth = gutterSeparatorWidth
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

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        let width = proposal.width ?? nsView.frame.size.width
        let height = proposal.height ?? nsView.frame.size.height
        return CGSize(width: width, height: height)
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

        // Update custom gutter — the factory may capture new SwiftUI state
        if gutterWidth > 0 {
            if textView.customGutterWidth != gutterWidth {
                textView.customGutterWidth = gutterWidth
            }
            textView.gutterLineViewProvider = gutterLineViewFactory
            textView.customGutterBackgroundColor = gutterBackgroundColor
            textView.customGutterSeparatorColor = gutterSeparatorColor
            textView.customGutterSeparatorWidth = gutterSeparatorWidth
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
