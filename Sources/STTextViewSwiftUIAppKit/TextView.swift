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
    private let textViewType: STTextView.Type

    /// Create a text edit view with a certain text that uses a certain options.
    /// - Parameters:
    ///   - text: The attributed string content
    ///   - selection: The current selection range
    ///   - options: Editor options
    ///   - plugins: Editor plugins
    ///   - textViewType: The ``STTextView`` subclass to instantiate
    public init(
        text: Binding<AttributedString>,
        selection: Binding<NSRange?> = .constant(nil),
        options: Options = [],
        plugins: [any STPlugin] = [],
        textViewType: STTextView.Type = STTextView.self
    ) {
        _text = text
        _selection = selection
        self.options = options
        self.plugins = plugins
        self.textViewType = textViewType
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection,
            options: options,
            plugins: plugins,
            textViewType: textViewType
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
    @Environment(\.gutterShadow) private var envGutterShadow

    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?
    private let options: Options
    private let plugins: [any STPlugin]
    private let textViewType: STTextView.Type
    private let gutterWidth: CGFloat
    private let gutterLineViewFactory: (Int, String) -> NSView
    /// Returns only the AnyView for the given line, used to update an existing NSHostingView
    /// in-place (cheaper than allocating a new hosting view for every layout pass).
    private let gutterViewUpdater: (Int, String) -> AnyView
    /// Opaque identity value for the current gutter data.
    /// When this changes between SwiftUI updates, the gutter line views are reloaded
    /// so they pick up the new data. When it is unchanged (e.g. normal keystroke that
    /// doesn't alter syllable counts or rhyme labels), the reload is skipped — preventing
    /// the expensive NSHostingView destruction+recreation on every character typed.
    private let gutterDataID: AnyHashable?

    /// Create a text editor with a custom per-line gutter.
    ///
    /// - Parameters:
    ///   - text: The attributed string content
    ///   - selection: The current selection range
    ///   - options: Editor options
    ///   - plugins: Editor plugins
    ///   - textViewType: The ``STTextView`` subclass to instantiate
    ///   - gutterWidth: Width reserved for the custom gutter area (in points)
    ///   - gutterDataID: Opaque hash identity for the current gutter data. Pass a value that
    ///     changes when the gutter content should be refreshed (e.g. `AnyHashable(rulerData)`).
    ///     When `nil`, the gutter is always reloaded on every SwiftUI update (legacy behaviour).
    ///   - gutterContent: A view builder called for each visible line with `(lineNumber, lineContent)`
    public init(
        text: Binding<AttributedString>,
        selection: Binding<NSRange?> = .constant(nil),
        options: Options = [],
        plugins: [any STPlugin] = [],
        textViewType: STTextView.Type = STTextView.self,
        gutterWidth: CGFloat,
        gutterDataID: AnyHashable? = nil,
        @ViewBuilder gutterContent: @escaping (_ lineNumber: Int, _ lineContent: String) -> GutterContent
    ) {
        _text = text
        _selection = selection
        self.options = options
        self.plugins = plugins
        self.textViewType = textViewType
        self.gutterWidth = gutterWidth
        self.gutterDataID = gutterDataID
        self.gutterLineViewFactory = { lineNumber, lineContent in
            NSHostingView(rootView: AnyView(gutterContent(lineNumber, lineContent)))
        }
        self.gutterViewUpdater = { lineNumber, lineContent in
            AnyView(gutterContent(lineNumber, lineContent))
        }
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection,
            options: options,
            plugins: plugins,
            textViewType: textViewType,
            gutterWidth: gutterWidth,
            gutterDataID: gutterDataID,
            gutterLineViewFactory: gutterLineViewFactory,
            gutterViewUpdater: gutterViewUpdater,
            gutterBackgroundColor: envGutterBackgroundColor,
            gutterSeparatorColor: envGutterSeparatorColor,
            gutterSeparatorWidth: envGutterSeparatorWidth,
            gutterShadow: envGutterShadow
        )
        .background(.background)
    }
}

// MARK: - Overscroll

/// Environment key for overscroll fraction (fraction of viewport height added below last line).
private struct OverscrollFractionKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Fraction of the viewport height to add as overscroll below the last text line.
    /// `0.5` = half-page overscroll. `0` (default) disables overscroll.
    var overscrollFraction: CGFloat {
        get { self[OverscrollFractionKey.self] }
        set { self[OverscrollFractionKey.self] = newValue }
    }
}

public extension TextViewModifier {

    /// Adds overscroll space below the last line of text.
    ///
    /// The `fraction` is relative to the visible viewport height — `0.5` allows the last
    /// line to scroll up to the vertical midpoint of the editor. Overscroll only activates
    /// when content already overflows the viewport, so short documents show no scrollbar.
    func overscrollFraction(_ fraction: CGFloat) -> TextViewEnvironmentModifier<Self, CGFloat> {
        TextViewEnvironmentModifier(content: self, keyPath: \.overscrollFraction, value: fraction)
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

/// Environment key for custom gutter shadow.
private struct GutterShadowKey: EnvironmentKey {
    static let defaultValue: NSShadow? = nil
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

    var gutterShadow: NSShadow? {
        get { self[GutterShadowKey.self] }
        set { self[GutterShadowKey.self] = newValue }
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

    /// Applies a shadow to the custom gutter container, cast onto the editor content area.
    func gutterShadow(_ shadow: NSShadow?) -> TextViewEnvironmentModifier<Self, NSShadow?> {
        TextViewEnvironmentModifier(content: self, keyPath: \.gutterShadow, value: shadow)
    }
}

// MARK: - Scroll Restoration & Observation

/// Environment key for one-shot scroll offset restoration.
/// When non-nil, the scroll view scrolls to this Y offset on the next update,
/// then the value is consumed (ignored on subsequent updates until it changes).
private struct ScrollRestorationOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

/// Environment key for continuous scroll offset change reporting.
/// The closure is called whenever the user scrolls (or the content scrolls programmatically).
private struct ScrollOffsetChangeHandlerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (@MainActor (CGFloat) -> Void)? = nil
}

extension EnvironmentValues {
    var scrollRestorationOffset: CGFloat? {
        get { self[ScrollRestorationOffsetKey.self] }
        set { self[ScrollRestorationOffsetKey.self] = newValue }
    }

    var scrollOffsetChangeHandler: (@MainActor (CGFloat) -> Void)? {
        get { self[ScrollOffsetChangeHandlerKey.self] }
        set { self[ScrollOffsetChangeHandlerKey.self] = newValue }
    }
}

public extension TextViewModifier {

    /// Restores the scroll position to the given Y offset.
    ///
    /// The offset is applied once when it transitions from `nil` to a value.
    /// Set to `nil` after the view appears, then set to the saved offset to trigger restoration.
    func scrollRestoration(offset: CGFloat?) -> TextViewEnvironmentModifier<Self, CGFloat?> {
        TextViewEnvironmentModifier(content: self, keyPath: \.scrollRestorationOffset, value: offset)
    }

    /// Reports scroll offset changes as the user scrolls.
    ///
    /// The handler receives the `contentView.bounds.origin.y` value of the scroll view's clip view.
    func onScrollOffsetChange(_ handler: @escaping @MainActor (CGFloat) -> Void) -> TextViewEnvironmentModifier<Self, (@MainActor (CGFloat) -> Void)?> {
        TextViewEnvironmentModifier(content: self, keyPath: \.scrollOffsetChangeHandler, value: handler)
    }
}

// MARK: - Gutter Data Source Adapter

/// Bridges a closure-based view factory to the ``STGutterLineViewDataSource`` protocol.
/// Stored on the SwiftUI coordinator so it stays alive while the text view holds a weak reference.
///
/// `viewFactory` creates a new `NSHostingView<AnyView>` for the initial layout (full allocation).
/// `viewUpdater` returns only the `AnyView` for in-place `rootView` updates — cheaper because
/// it does not allocate an NSHostingView; instead the existing hosting view's rootView is replaced
/// via a lightweight SwiftUI reconciliation call. This avoids the ~500 ms stutter caused by
/// destroying and recreating all visible NSHostingViews on every layout pass.
private class GutterLineViewDataSourceAdapter: STGutterLineViewDataSource {
    /// Returns a new NSHostingView wrapping the gutter content for the given line.
    var factory: (Int, String) -> NSView
    /// Returns the AnyView for the given line, used to update an existing hosting view in-place.
    var viewUpdater: ((Int, String) -> AnyView)?

    init(factory: @escaping (Int, String) -> NSView, viewUpdater: ((Int, String) -> AnyView)? = nil) {
        self.factory = factory
        self.viewUpdater = viewUpdater
    }

    func textView(_ textView: STTextView, viewForGutterLine lineNumber: Int, content: String) -> NSView {
        factory(lineNumber, content)
    }

    func textView(_ textView: STTextView, updateView existingView: NSView, forGutterLine lineNumber: Int, content: String) -> Bool {
        // Require both an updater and a castable hosting view.
        guard let updater = viewUpdater,
              let hostingView = existingView as? NSHostingView<AnyView> else {
            return false
        }
        // Assign the new AnyView directly to the existing hosting view.
        // This is a lightweight SwiftUI reconciliation, not an NSView allocation.
        hostingView.rootView = updater(lineNumber, content)
        return true
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
    @Environment(\.overscrollFraction)
    private var overscrollFraction
    @Environment(\.scrollRestorationOffset)
    private var scrollRestorationOffset
    @Environment(\.scrollOffsetChangeHandler)
    private var scrollOffsetChangeHandler

    @Binding
    private var text: AttributedString
    @Binding
    private var selection: NSRange?
    private let options: TextView.Options
    private var plugins: [any STPlugin]
    private let textViewType: STTextView.Type
    let gutterWidth: CGFloat
    /// Opaque identity for the current gutter data — see `TextViewWithGutter.gutterDataID`.
    let gutterDataID: AnyHashable?
    let gutterLineViewFactory: ((Int, String) -> NSView)?
    /// Returns only the AnyView for the given line, used to update existing NSHostingViews
    /// in-place without allocating a new hosting view (avoids the stutter on layout passes).
    let gutterViewUpdater: ((Int, String) -> AnyView)?
    let gutterBackgroundColor: NSColor?
    let gutterSeparatorColor: NSColor?
    let gutterSeparatorWidth: CGFloat
    let gutterShadow: NSShadow?

    init(text: Binding<AttributedString>, selection: Binding<NSRange?>, options: TextView.Options, plugins: [any STPlugin] = [], textViewType: STTextView.Type = STTextView.self, gutterWidth: CGFloat = 0, gutterDataID: AnyHashable? = nil, gutterLineViewFactory: ((Int, String) -> NSView)? = nil, gutterViewUpdater: ((Int, String) -> AnyView)? = nil, gutterBackgroundColor: NSColor? = nil, gutterSeparatorColor: NSColor? = nil, gutterSeparatorWidth: CGFloat = 0, gutterShadow: NSShadow? = nil) {
        self._text = text
        self._selection = selection
        self.options = options
        self.plugins = plugins
        self.textViewType = textViewType
        self.gutterWidth = gutterWidth
        self.gutterDataID = gutterDataID
        self.gutterLineViewFactory = gutterLineViewFactory
        self.gutterViewUpdater = gutterViewUpdater
        self.gutterBackgroundColor = gutterBackgroundColor
        self.gutterSeparatorColor = gutterSeparatorColor
        self.gutterSeparatorWidth = gutterSeparatorWidth
        self.gutterShadow = gutterShadow
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = textViewType.scrollableTextView()
        // Disable automatic content insets — SwiftUI handles safe area layout externally.
        // Without this, macOS adds a topContentInset when the scroll view overlaps the title bar,
        // triggering the FB21059465 gutter workaround that shifts the gutter container above the
        // scroll view's clip boundary, causing the first-line gutter label to be clipped.
        scrollView.automaticallyAdjustsContentInsets = false
        let textView = scrollView.documentView as! STTextView
        textView.textDelegate = context.coordinator
        textView.highlightSelectedLine = options.contains(.highlightSelectedLine)
        textView.isHorizontallyResizable = !options.contains(.wrapLines)
        if options.contains(.wrapLines) {
            // Wrapping lines means horizontal scrolling is never needed.
            scrollView.hasHorizontalScroller = false
        }
        textView.overscrollFraction = overscrollFraction
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
        if gutterWidth > 0, let factory = gutterLineViewFactory {
            textView.customGutterWidth = gutterWidth
            let adapter = GutterLineViewDataSourceAdapter(factory: factory, viewUpdater: gutterViewUpdater)
            context.coordinator.gutterDataSourceAdapter = adapter
            context.coordinator.lastGutterDataID = gutterDataID
            textView.gutterLineViewDataSource = adapter
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

        // Observe scroll position changes via the clip view's bounds notifications.
        scrollView.contentView.postsBoundsChangedNotifications = true
        context.coordinator.scrollObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak scrollView, weak coordinator = context.coordinator] _ in
            guard let scrollView, let coordinator else { return }
            let offset = scrollView.contentView.bounds.origin.y
            MainActor.assumeIsolated {
                coordinator.scrollOffsetChangeHandler?(offset)
            }
        }

        // Store initial scroll offset change handler
        context.coordinator.scrollOffsetChangeHandler = scrollOffsetChangeHandler

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

        if textView.overscrollFraction != overscrollFraction {
            textView.overscrollFraction = overscrollFraction
        }

        if textView.showsLineNumbers != options.contains(.showLineNumbers) {
            textView.showsLineNumbers = options.contains(.showLineNumbers)
            if options.contains(.showLineNumbers) {
                textView.gutterView?.font = textView.font
                textView.gutterView?.textColor = .secondaryLabelColor
            }
        }

        // Update custom gutter — the factory may capture new SwiftUI state.
        // When a gutterDataID is provided, only call reloadGutterLineViews() when the
        // ID actually changes, preventing expensive NSHostingView destruction+recreation
        // on every keystroke. Without an ID, fall back to always reloading (legacy behaviour).
        if gutterWidth > 0, let factory = gutterLineViewFactory {
            if textView.customGutterWidth != gutterWidth {
                textView.customGutterWidth = gutterWidth
            }
            if let adapter = context.coordinator.gutterDataSourceAdapter {
                // Update both closures so they always capture the latest SwiftUI state.
                adapter.factory = factory
                adapter.viewUpdater = gutterViewUpdater
                // Reload only when gutter data has actually changed.
                // gutterDataID == nil means no ID was supplied — always reload (legacy path).
                let dataChanged: Bool
                if let id = gutterDataID {
                    dataChanged = id != context.coordinator.lastGutterDataID
                } else {
                    dataChanged = true
                }
                if dataChanged {
                    context.coordinator.lastGutterDataID = gutterDataID
                    textView.reloadGutterLineViews()
                }
            } else {
                let adapter = GutterLineViewDataSourceAdapter(factory: factory, viewUpdater: gutterViewUpdater)
                context.coordinator.gutterDataSourceAdapter = adapter
                context.coordinator.lastGutterDataID = gutterDataID
                textView.gutterLineViewDataSource = adapter
            }
            textView.customGutterBackgroundColor = gutterBackgroundColor
            textView.customGutterSeparatorColor = gutterSeparatorColor
            textView.customGutterSeparatorWidth = gutterSeparatorWidth
        } else if textView.customGutterWidth > 0 {
            // Gutter was previously configured but is now disabled — clean up
            textView.customGutterWidth = 0
            textView.gutterLineViewDataSource = nil
            context.coordinator.gutterDataSourceAdapter = nil
            textView.customGutterBackgroundColor = nil
            textView.customGutterSeparatorColor = nil
        }

        // Apply gutter shadow from the app layer — set on the container view
        // which is created lazily by STTextView during layout.
        textView.customGutterContainerView?.shadow = gutterShadow

        // Keep scroll offset change handler up to date
        context.coordinator.scrollOffsetChangeHandler = scrollOffsetChangeHandler

        // Apply one-shot scroll restoration when the offset changes
        if let offset = scrollRestorationOffset, offset != context.coordinator.lastRestoredScrollOffset {
            context.coordinator.lastRestoredScrollOffset = offset
            // Defer scroll to after layout completes so the text view has its final size.
            DispatchQueue.main.async {
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: offset))
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        } else if scrollRestorationOffset == nil {
            // Reset tracking so the next non-nil value triggers restoration
            context.coordinator.lastRestoredScrollOffset = nil
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
        /// Keeps the gutter data source adapter alive while the text view holds a weak reference.
        var gutterDataSourceAdapter: GutterLineViewDataSourceAdapter?
        /// The gutter data ID from the last updateNSView call.
        /// Used to skip reloadGutterLineViews() when the gutter data has not changed.
        var lastGutterDataID: AnyHashable?
        /// Scroll observation token for NSView.boundsDidChangeNotification.
        var scrollObserver: (any NSObjectProtocol)?
        /// Callback invoked when the scroll offset changes.
        var scrollOffsetChangeHandler: (@MainActor (CGFloat) -> Void)?
        /// Tracks the last restored scroll offset to avoid re-applying on every update.
        var lastRestoredScrollOffset: CGFloat?

        init(text: Binding<AttributedString>, selection: Binding<NSRange?>) {
            self._text = text
            self._selection = selection
        }

        deinit {
            if let scrollObserver {
                NotificationCenter.default.removeObserver(scrollObserver)
            }
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
