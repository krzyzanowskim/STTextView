//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  NSScrollView
//      |---STTextView
//          |---gutterView
//          |---contentView
//              |---STInsertionPointView
//              |---selectionView
//                  |---(STLineHighlightView | SelectionHighlightView)
//              |---contentViewportView
//                  |---STTextLayoutFragmentView
//
//
// The default implementation of the NSView method inputContext manages
// an NSTextInputContext instance automatically if the view subclass conforms
// to the NSTextInputClient protocol.
//
// Although NSTextInput is deprecated, it seem to be check here and there
// whether view conforms to NSTextInput, hence it's here along the NSTextInputClient

import AppKit
import STTextKitPlus
import STTextViewCommon
import AVFoundation

/// A TextKit2 text view without NSTextView baggage
@objc open class STTextView: NSView, NSTextInput, NSTextContent, STTextViewProtocol {
    /// Posted before an object performs any operation that changes characters or formatting attributes.
    public static let textWillChangeNotification = NSNotification.Name("NSTextWillChangeNotification")

    /// Sent when the text in the receiving control changes.
    public static let textDidChangeNotification = NSText.didChangeNotification

    /// Sent when the selection range of characters changes.
    public static let didChangeSelectionNotification = STTextLayoutManager.didChangeSelectionNotification

    /// Installed plugins. events value is available after plugin is setup
    internal var plugins: [Plugin] = []

    /// A Boolean value that controls whether the text view allows the user to edit text.
    @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isEditable: Bool = true {
        didSet {
            if isEditable == true {
                isSelectable = true
            }
        }
    }

    /// A Boolean value that controls whether the text views allows the user to select text.
    @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isSelectable: Bool = true {
        didSet {
            if isSelectable == false {
                isEditable = false
            }
        }
    }

    @objc public let isRichText: Bool = true
    @objc public let isFieldEditor: Bool = false
    @objc public let importsGraphics: Bool = false

    /// A Boolean value that determines whether the text view should draw its insertion point.
    open var shouldDrawInsertionPoint: Bool {
        if !isFirstResponder {
            return false
        }

        if !isEditable {
            return false
        }

        if let window = window, window.isKeyWindow, window.firstResponder == self {
            return true
        }

        return false
    }

    @Invalidating(.insertionPoint, .cursorRects)
    internal var isFirstResponder: Bool = false

    /// The color of the insertion point.
    @Invalidating(.display, .insertionPoint)
    @objc dynamic open var insertionPointColor: NSColor = .defaultTextInsertionPoint

    /// The font of the text. Default font.
    ///
    /// Assigning a new value to this property causes the new font to be applied to the entire contents of the text view.
    /// If you want to apply the font to only a portion of the text, you must create a new attributed string with the desired style information and assign it
    @MainActor
    @objc public var font: NSFont {
        get {
            _defaultTypingAttributes[.font] as! NSFont
        }

        set {
            _defaultTypingAttributes[.font] = newValue

            // apply to the document
            if !textLayoutManager.documentRange.isEmpty {
                addAttributes([.font: newValue], range: textLayoutManager.documentRange)
                needsLayout = true
                needsDisplay = true
            }

            updateTypingAttributes()
        }
    }

    /// The text color of the text view.
    ///
    /// Default text color.
    @MainActor
    @objc public var textColor: NSColor {
        get {
            _defaultTypingAttributes[.foregroundColor] as! NSColor
        }

        set {
            _defaultTypingAttributes[.foregroundColor] = newValue

            // apply to the document
            if !textLayoutManager.documentRange.isEmpty {
                addAttributes([.foregroundColor: newValue], range: textLayoutManager.documentRange)
                needsLayout = true
                needsDisplay = true
            }

            updateTypingAttributes()
        }
    }

    /// Default paragraph style.
    @MainActor
    @objc public var defaultParagraphStyle: NSParagraphStyle {
        set {
            _defaultTypingAttributes[.paragraphStyle] = newValue
        }
        get {
            _defaultTypingAttributes[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
        }
    }

    /// Default typing attributes used in place of missing attributes of font, color and paragraph
    internal var _defaultTypingAttributes: [NSAttributedString.Key: Any] = [
        .paragraphStyle: NSParagraphStyle.default,
        .font: NSFont.preferredFont(forTextStyle: .body),
        .foregroundColor: NSColor.textColor
    ]

    /// The attributes to apply to new text that the user enters.
    ///
    /// This dictionary contains the attribute keys (and corresponding values) to apply to newly typed text.
    /// When the text view’s selection changes, the contents of the dictionary are reset automatically.
    @objc public internal(set) var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            _typingAttributes.merging(_defaultTypingAttributes) { (current, _) in current }
        }

        set {
            _typingAttributes = newValue.filter {
                _allowedTypingAttributes.contains($0.key)
            }
            needsDisplay = true
        }
    }

    private var _typingAttributes: [NSAttributedString.Key: Any]
    private var _allowedTypingAttributes: [NSAttributedString.Key] = [
        .paragraphStyle,
        .font,
        .foregroundColor,
        .baselineOffset,
        .kern,
        .ligature,
        .shadow,
        .strikethroughColor,
        .strikethroughStyle,
        .superscript,
        .languageIdentifier,
        .tracking,
        .writingDirection,
        .textEffect,
        .accessibilityFont,
        .accessibilityForegroundColor,
        .backgroundColor,
        .baselineOffset,
        .underlineColor,
        .underlineStyle,
        .accessibilityUnderline,
        .accessibilityUnderlineColor
    ]

    internal func updateTypingAttributes(at location: NSTextLocation? = nil) {
        if let location {
            self.typingAttributes = typingAttributes(at: location)
        } else {
            // TODO: doesn't work work correctly (at all) for multiple insertion points where each has different typing attribute
            if let insertionPointSelection = textLayoutManager.insertionPointSelections.first,
               let startLocation = insertionPointSelection.textRanges.first?.location
            {
                self.typingAttributes = typingAttributes(at: startLocation)
            }
        }
    }

    internal func typingAttributes(at startLocation: NSTextLocation) -> [NSAttributedString.Key : Any] {
        if textLayoutManager.documentRange.isEmpty {
            return _defaultTypingAttributes
        }

        var typingAttrs: [NSAttributedString.Key: Any] = [:]
        // The attribute is derived from the previous (upstream) location,
        // except for the beginning of the document where it from whatever is at location 0
        let options: NSTextContentManager.EnumerationOptions = startLocation == textLayoutManager.documentRange.location ? [] : [.reverse]
        let offsetDiff = startLocation == textLayoutManager.documentRange.location ? 0 : -1

        textContentManager.enumerateTextElements(from: startLocation, options: options) { textElement in
            if let attributedTextElement = textElement as? STAttributedTextElement,
               let elementRange = textElement.elementRange,
               let textContentManager = textElement.textContentManager
            {
                let offset = textContentManager.offset(from: elementRange.location, to: startLocation)
                assert(offset != NSNotFound, "Unexpected location")
                typingAttrs = attributedTextElement.attributedString.attributes(at: offset + offsetDiff, effectiveRange: nil)
            }

            return false
        }

        // fill in with missing typing attributes if needed
        return typingAttrs.merging(_defaultTypingAttributes, uniquingKeysWith: { current, _ in current})
    }

    // line height based on current typing font and current typing paragraph
    internal var typingLineHeight: CGFloat {
        let font = typingAttributes[.font] as? NSFont ?? _defaultTypingAttributes[.font] as! NSFont
        let paragraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? self._defaultTypingAttributes[.paragraphStyle] as! NSParagraphStyle
        return calculateDefaultLineHeight(for: font) * paragraphStyle.stLineHeightMultiple
    }

    /// The characters of the receiver’s text.
    ///
    /// For performance reasons, this value is the current backing store of the text object.
    /// If you want to maintain a snapshot of this as you manipulate the text storage, you should make a copy of the appropriate substring.
    @objc open var text: String? {
        set {
            let prevLocation = textLayoutManager.insertionPointLocations.first

            setString(newValue)

            if let prevLocation {
                // restore selection location
                setSelectedTextRange(NSTextRange(location: prevLocation), updateLayout: true)
            } else {
                // or try to set at the begining of the document
                setSelectedTextRange(NSTextRange(location: textContentManager.documentRange.location), updateLayout: true)
            }
        }
        get {
            textContentManager.attributedString(in: nil)?.string ?? ""
        }
    }

    /// The styled text that the text view displays.
    ///
    /// Assigning a new value to this property also replaces the value of the `text` property with the same string data, albeit without any formatting information. In addition, the `font`, `textColor`, and `textAlignment` properties are updated to reflect the typing attributes of the text view.
    @objc open var attributedText: NSAttributedString? {
        set {
            let prevLocation = textLayoutManager.insertionPointLocations.first

            setString(newValue)

            if let prevLocation {
                // restore selection location
                setSelectedTextRange(NSTextRange(location: prevLocation), updateLayout: true)
            } else {
                // or try to set at the begining of the document
                setSelectedTextRange(NSTextRange(location: textContentManager.documentRange.location), updateLayout: true)
            }
        }
        get {
            textContentManager.attributedString(in: nil)
        }
    }

    /// A Boolean that controls whether the text container adjusts the width of its bounding rectangle when its text view resizes.
    ///
    /// When the value of this property is `true`, the text container adjusts its width when the width of its text view changes. The default value of this property is `false`.
    ///
    /// - Note: If you set both `widthTracksTextView` and `isHorizontallyResizable` up to resize automatically in the same dimension, your application can get trapped in an infinite loop.
    ///
    /// - SeeAlso: [Tracking the Size of a Text View](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html#//apple_ref/doc/uid/20000927-CJBBIAAF)
    @objc public var widthTracksTextView: Bool {
        set {
            if textContainer.widthTracksTextView != newValue {
                textContainer.widthTracksTextView = newValue
                textContainer.size = _defaultTextContainerSize
                needsLayout = true
            }
        }

        get {
            textContainer.widthTracksTextView
        }
    }

    /// A Boolean that controls whether the receiver changes its width to fit the width of its text.
    @objc public var isHorizontallyResizable: Bool {
        set {
            widthTracksTextView = newValue
        }

        get {
            widthTracksTextView
        }
    }

    /// A Boolean that controls whether the text container adjusts the height of its bounding rectangle when its text view resizes.
    ///
    /// When the value of this property is `true`, the text container adjusts its height when the height of its text view changes. The default value of this property is `false`.
    ///
    /// - Note: If you set both `heightTracksTextView` and `isVerticallyResizable` up to resize automatically in the same dimension, your application can get trapped in an infinite loop.
    ///
    /// - SeeAlso: [Tracking the Size of a Text View](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html#//apple_ref/doc/uid/20000927-CJBBIAAF)
    @objc public var heightTracksTextView: Bool {
        set {
            if textContainer.heightTracksTextView != newValue {
                textContainer.heightTracksTextView = newValue
                textContainer.size = _defaultTextContainerSize
                needsLayout = true
            }
        }

        get {
            textContainer.heightTracksTextView
        }
    }

    /// A Boolean that controls whether the receiver changes its height to fit the height of its text.
    @objc public var isVerticallyResizable: Bool {
        set {
            heightTracksTextView = newValue
        }

        get {
            heightTracksTextView
        }
    }

    /// A Boolean that controls whether the text view highlights the currently selected line.
    @MainActor @Invalidating(.layoutViewport)
    @objc dynamic open var highlightSelectedLine: Bool = false

    /// Extra padding below the text content for "scroll past end" behavior.
    ///
    /// When set to a value greater than 0:
    /// - The padding is added to the frame height in `sizeToFit()`
    /// - Viewport relocation logic is skipped to prevent scroll position jumps
    ///
    /// Default is `0` (no extra padding).
    @MainActor
    open var bottomPadding: CGFloat = 0

    /// Extra padding to the right of text content for accessory views.
    ///
    /// When set to a value greater than 0:
    /// - The padding is added to the frame width in `sizeToFit()`
    /// - Provides space for overlay views like annotation margins
    ///
    /// Default is `0` (no extra padding).
    @MainActor
    open var rightPadding: CGFloat = 0

    /// Custom annotation decorations to render on text (underlines, backgrounds).
    ///
    /// Set this property to display decorations at specific character ranges.
    /// Decorations are rendered efficiently, only drawing for visible text.
    /// Setting this property triggers a redisplay of affected fragments.
    ///
    /// Example:
    /// ```swift
    /// textView.annotationDecorations = [
    ///     STAnnotationDecoration(range: NSRange(location: 0, length: 10),
    ///                            style: .wavyUnderline, color: .systemRed),
    ///     STAnnotationDecoration(range: NSRange(location: 20, length: 5),
    ///                            style: .background, color: .systemYellow.withAlphaComponent(0.3))
    /// ]
    /// ```
    @MainActor
    open var annotationDecorations: [STAnnotationDecoration] = [] {
        didSet {
            // Redisplay affected fragments
            needsDisplay = true
            contentViewportView.needsDisplay = true
            for subview in contentViewportView.subviews {
                subview.needsDisplay = true
            }
        }
    }

    /// Enable to show line numbers in the gutter.
    @MainActor @Invalidating(.layout)
    open var showsLineNumbers: Bool = false {
        didSet {
            isGutterVisible = showsLineNumbers
        }
    }

    /// Gutter view
    public var gutterView: STGutterView?

    /// The highlight color of the selected line.
    ///
    /// Note: Needs ``highlightSelectedLine`` to be set to `true`
    @Invalidating(.display)
    @objc dynamic open var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)

    /// The text view's background color
    @Invalidating(.display)
    @objc dynamic open var backgroundColor: NSColor? = nil {
        didSet {
            layer?.backgroundColor = backgroundColor?.cgColor
        }
    }

    /// A Boolean value that indicates whether the receiver allows its background color to change.
    @objc open dynamic var allowsDocumentBackgroundColorChange: Bool = true

    /// An action method used to set the background color.
    @objc open func changeDocumentBackgroundColor(_ sender: Any?) {
        guard allowsDocumentBackgroundColorChange, let color = sender as? NSColor else {
            return
        }

        backgroundColor = color
    }

    /// The semantic meaning for a text input area.
    open var contentType: NSTextContentType?

    /// A Boolean value that indicates whether the receiver allows undo.
    ///
    /// `true` if the receiver allows undo, otherwise `false`. Default `true`.
    @objc dynamic open var allowsUndo: Bool
    internal var _undoManager: UndoManager?
    internal var _yankingManager = YankingManager()

    internal var markedText: STMarkedText? = nil

    /// The attributes used to draw marked text.
    ///
    /// Text color, background color, and underline are the only supported attributes for marked text.
    @objc open var markedTextAttributes: [NSAttributedString.Key : Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue]

    /// A flag
    internal var processingKeyEvent: Bool = false

    /// The delegate for all text views sharing the same layout manager.
    @available(*, deprecated, renamed: "textDelegate")
    public weak var delegate: (any STTextViewDelegate)? {
        set {
            textDelegate = newValue
        }

        get {
            textDelegate
        }
    }

    /// The delegate for all text views sharing the same layout manager.
    public weak var textDelegate: (any STTextViewDelegate)? {
        set {
            delegateProxy.source = newValue
        }

        get {
            delegateProxy.source
        }
    }

    /// Proxy for delegate calls
    internal let delegateProxy = STTextViewDelegateProxy(source: nil)

    /// The manager that lays out text for the text view's text container.
    @objc dynamic open var textLayoutManager: NSTextLayoutManager {
        willSet {
            textContentManager.primaryTextLayoutManager = nil
            textContentManager.removeTextLayoutManager(newValue)
        }
        didSet {
            textContentManager.addTextLayoutManager(textLayoutManager)
            textContentManager.primaryTextLayoutManager = textLayoutManager
            setupTextLayoutManager(textLayoutManager)
            self.text = text
        }
    }

    @available(*, deprecated, renamed: "textContentManager")
    open var textContentStorage: NSTextContentStorage {
        textContentManager as! NSTextContentStorage
    }

    /// The text view's text storage object.
    @objc dynamic open var textContentManager: NSTextContentManager {
        willSet {
            textContentManager.primaryTextLayoutManager = nil
        }
        didSet {
            textContentManager.addTextLayoutManager(textLayoutManager)
            textContentManager.primaryTextLayoutManager = textLayoutManager
            self.text = text
        }
    }

    /// The text view's text container
    public var textContainer: NSTextContainer {
        get {
            textLayoutManager.textContainer!
        }

        set {
            textLayoutManager.textContainer = newValue
        }
    }

    /// Content view. Layout fragments content.
    internal let contentView: STContentView
    internal let contentViewportView: STContentViewportView

    /// Content frame. Layout fragments content frame.
    public var contentFrame: CGRect {
        contentView.frame
    }

    /// Selection highlight content view.
    internal let selectionView: STSelectionView

    internal var fragmentViewMap: NSMapTable<NSTextLayoutFragment, STTextLayoutFragmentView>
    private var _usageBoundsForTextContainerObserver: NSKeyValueObservation?

    internal lazy var _speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private lazy var _defaultTextContainerSize: CGSize = NSTextContainer().size

    internal var _completionWindowController: STCompletionWindowController?
    internal var completionWindowController: STCompletionWindowController? {
        if _completionWindowController == nil {
            let completionViewController = delegateProxy.textViewCompletionViewController(self)
            let completionWindowController = STCompletionWindowController(completionViewController)
            _completionWindowController = completionWindowController
            return completionWindowController
        }

        return _completionWindowController
    }

    /// Completion window is presented currently
    open var isCompletionActive: Bool {
        completionWindowController?.isVisible == true
    }

    /// Cancel completion task on selection change automatically. Default `true`.
    ///
    /// Automatically call ``cancelComplete(_:)`` when `true`.
    open var shouldDimissCompletionOnSelectionChange: Bool = true

    internal var _completionTask: Task<Void, any Error>?

    /// Search-and-replace find interface inside a view.
    open private(set) var textFinder: NSTextFinder

    /// NSTextFinderClient
    internal let textFinderClient: STTextFinderClient

    internal let textFinderBarContainer: STTextFinderBarContainer

    internal var textCheckingController: NSTextCheckingController!

    /// A Boolean value that indicates whether the receiver has continuous spell checking enabled.
    ///
    /// true if the object has continuous spell-checking enabled; otherwise, false.
    @objc public var isContinuousSpellCheckingEnabled: Bool = false

    /// Enables and disables grammar checking.
    ///
    /// If true, grammar checking is enabled; if false, it is disabled.
    @objc public var isGrammarCheckingEnabled: Bool = false

    /// A Boolean value that indicates whether the text view supplies autocompletion suggestions as the user types.
    @objc public lazy var isAutomaticTextCompletionEnabled: Bool = NSSpellChecker.isAutomaticTextCompletionEnabled

    /// A Boolean value that indicates whether automatic spelling correction is enabled.
    @objc public lazy var isAutomaticSpellingCorrectionEnabled: Bool = NSSpellChecker.isAutomaticSpellingCorrectionEnabled

    /// A Boolean value that indicates whether automatic text replacement is enabled.
    @objc public lazy var isAutomaticTextReplacementEnabled = NSSpellChecker.isAutomaticTextReplacementEnabled

    /// A Boolean value that enables and disables automatic quotation mark substitution.
    @objc public lazy var isAutomaticQuoteSubstitutionEnabled = NSSpellChecker.isAutomaticQuoteSubstitutionEnabled

    /// A Boolean value that indicates whether to substitute visible glyphs for whitespace and other typically invisible characters.
    @Invalidating(.layoutViewport, .display)
    public var showsInvisibleCharacters: Bool = false {
        willSet {
            textLayoutManager.invalidateLayout(for: textLayoutManager.textViewportLayoutController.viewportRange ?? textLayoutManager.documentRange)
        }
    }

    /// A Boolean value that indicates whether incremental searching is enabled.
    ///
    /// See `NSTextFinder` for information about the find bar.
    ///
    /// The default value is false.
    public var isIncrementalSearchingEnabled: Bool {
        get {
            textFinder.isIncrementalSearchingEnabled
        }
        set {
            textFinder.isIncrementalSearchingEnabled = newValue
        }
    }

    /// A Boolean value that controls whether the text views sharing the receiver’s layout manager use the Font panel and Font menu.
    open var usesFontPanel: Bool = true

    /// A Boolean value indicating whether the view needs scroll to visible selection pass before it can be drawn.
    internal var needsScrollToSelection: Bool = false {
        didSet {
            if needsScrollToSelection {
                needsLayout = true
            }
        }
    }

    open override var isFlipped: Bool {
        true
    }

    /// Generates and returns a scroll view with a STTextView set as its document view.
    open class func scrollableTextView(frame: NSRect = .zero) -> NSScrollView {
        let scrollView = NSScrollView(frame: frame)
        let textView = Self()

        scrollView.wantsLayer = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        return scrollView
    }

    internal var scrollView: NSScrollView? {
        guard let result = enclosingScrollView, result.documentView == self else {
            return nil
        }
        return result
    }

    /// A dragging selection anchor
    ///
    /// FB11898356 - Something if wrong with textSelectionsInteractingAtPoint
    /// it expects that the dragging operation does not change anchor selections
    /// significantly. Specifically it does not play well if anchor and current
    /// location is too close to each other, therefore `mouseDraggingSelectionAnchors`
    /// keep the anchors unchanged while dragging.
    internal var mouseDraggingSelectionAnchors: [NSTextSelection]? = nil
    internal var draggingSession: NSDraggingSession? = nil
    internal var originalDragSelections: [NSTextRange]? = nil

    open override class var defaultMenu: NSMenu? {
        // evaluated once, and cached
        let menu = super.defaultMenu ?? NSMenu()

        let pasteAsPlainText = NSMenuItem(title: NSLocalizedString("Paste and Match Style", comment: ""), action: #selector(pasteAsPlainText(_:)), keyEquivalent: "V")
        pasteAsPlainText.keyEquivalentModifierMask = [.option, .command, .shift]

        menu.items = [
            NSMenuItem(title: NSLocalizedString("Cut", comment: ""), action: #selector(cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: NSLocalizedString("Copy", comment: ""), action: #selector(copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: NSLocalizedString("Paste", comment: ""), action: #selector(paste(_:)), keyEquivalent: "v"),
            pasteAsPlainText,
            NSMenuItem.separator(),
            NSMenuItem(title: NSLocalizedString("Select All", comment: ""), action: #selector(selectAll(_:)), keyEquivalent: "a"),
        ]
        return menu
    }

    /// Initializes a text view.
    /// - Parameter frameRect: The frame rectangle of the text view.
    override public init(frame frameRect: NSRect) {
        fragmentViewMap = .weakToWeakObjects()

        textContentManager = STTextContentStorage()
        textLayoutManager = STTextLayoutManager()
        textLayoutManager.textContainer = STTextContainer()
        textLayoutManager.textContainer?.widthTracksTextView = false
        textLayoutManager.textContainer?.heightTracksTextView = true
        textContentManager.addTextLayoutManager(textLayoutManager)
        textContentManager.primaryTextLayoutManager = textLayoutManager

        contentView = STContentView()
        if ProcessInfo().environment["ST_LAYOUT_DEBUG"] == "YES" {
            contentView.layer?.borderColor = NSColor.magenta.cgColor
            contentView.layer?.borderWidth = 4
        }
        contentViewportView = STContentViewportView()
        contentViewportView.autoresizingMask = [.width, .height]

        selectionView = STSelectionView()
        selectionView.autoresizingMask = [.width, .height]

        allowsUndo = true
        _undoManager = CoalescingUndoManager()

        textFinderClient = STTextFinderClient()
        textFinderBarContainer = STTextFinderBarContainer()
        textFinder = NSTextFinder()
        textFinder.client = textFinderClient

        _typingAttributes = [:]

        super.init(frame: frameRect)

        textFinderBarContainer.client = self
        textFinder.findBarContainer = textFinderBarContainer

        textFinderClient.textView = self
        textCheckingController = NSTextCheckingController(client: self)

        postsBoundsChangedNotifications = true
        postsFrameChangedNotifications = true

        wantsLayer = true
        autoresizingMask = [.width, .height]

        addSubview(contentView)
        contentView.addSubview(selectionView)
        contentView.addSubview(contentViewportView)

        do {
            let recognizer = DragSelectedTextGestureRecognizer(target: self, action: #selector(_dragSelectedTextGestureRecognizer(gestureRecognizer:)))
            recognizer.minimumPressDuration = NSEvent.doubleClickInterval / 3
            recognizer.isEnabled = isSelectable
            addGestureRecognizer(recognizer)
        }

        setupTextLayoutManager(textLayoutManager)
        setSelectedTextRange(NSTextRange(location: textLayoutManager.documentRange.location), updateLayout: false)
        registerForDraggedTypes(readablePasteboardTypes)
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        guard !plugins.isEmpty else { return }
        Task { @MainActor [plugins] in
            plugins.forEach { plugin in
                plugin.instance.tearDown()
            }
        }
    }

    private var didChangeSelectionNotificationObserver: NSObjectProtocol?
    private func setupTextLayoutManager(_ textLayoutManager: NSTextLayoutManager) {
        textLayoutManager.delegate = self
        textLayoutManager.textViewportLayoutController.delegate = self

        // Forward didChangeSelectionNotification from STTextLayoutManager
        if let didChangeSelectionNotificationObserver {
            NotificationCenter.default.removeObserver(didChangeSelectionNotificationObserver)
        }
        didChangeSelectionNotificationObserver = NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }

            _yankingManager.selectionChanged()

            let textViewNotification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: notification.userInfo)

            NotificationCenter.default.post(textViewNotification)
            self.delegateProxy.textViewDidChangeSelection(textViewNotification)

            NSAccessibility.post(element: self, notification: .selectedTextChanged)

            // Cancel completinon on selection change
            if self.shouldDimissCompletionOnSelectionChange {
                if NSApp.currentEvent == nil ||
                    (NSApp.currentEvent?.type != .keyDown && NSApp.currentEvent?.type != .keyUp) ||
                    NSApp.currentEvent?.characters == nil ||
                    !(NSApp.currentEvent?.characters?.contains(where: \.isLetter) ?? false)
                {
                    self.cancelComplete(textViewNotification.object)
                }
            }

            // textCheckingController.didChangeSelectedRange()
        }

        _usageBoundsForTextContainerObserver = nil
        _usageBoundsForTextContainerObserver = textLayoutManager.observe(\.usageBoundsForTextContainer, options: [.initial, .new]) { [weak self] _, _ in
            // FB13291926: Notification no longer works. Fixed again in macOS 15.6
            self?.needsUpdateConstraints = true
        }
    }

    open override func resetCursorRects() {
        super.resetCursorRects()

        let contentViewVisibleRect = contentView.convert(contentView.visibleRect, to: self)
        if isSelectable, contentViewVisibleRect != .zero {
            addCursorRect(contentViewVisibleRect, cursor: .iBeam)

            // This iteration may be performance intensive. I think it can be debounced without
            // affecting the correctness
            if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange,
               let viewportAttributedString = textContentManager.attributedString(in: viewportRange)
            {
                viewportAttributedString.enumerateAttribute(.link, in: viewportAttributedString.range, options: .longestEffectiveRangeNotRequired) { attributeValue, attributeRange, stop in
                    guard attributeValue != nil else {
                        return
                    }

                    if let startLocation = textLayoutManager.location(viewportRange.location, offsetBy: attributeRange.location),
                       let endLocation = textLayoutManager.location(startLocation, offsetBy: attributeRange.length),
                       let linkTextRange = NSTextRange(location: startLocation, end: endLocation),
                       let linkTypographicBounds = textLayoutManager.typographicBounds(in: linkTextRange)
                    {
                        addCursorRect(contentView.convert(linkTypographicBounds, to: self), cursor: .pointingHand)
                    } else {
                        stop.pointee = true
                    }
                }

                viewportAttributedString.enumerateAttribute(.cursor, in: viewportAttributedString.range, options: .longestEffectiveRangeNotRequired) { attributeValue, attributeRange, stop in
                    guard let cursorValue = attributeValue as? NSCursor else {
                        return
                    }

                    if let startLocation = textLayoutManager.location(viewportRange.location, offsetBy: attributeRange.location),
                       let endLocation = textLayoutManager.location(startLocation, offsetBy: attributeRange.length),
                       let linkTextRange = NSTextRange(location: startLocation, end: endLocation),
                       let linkTypographicBounds = textLayoutManager.typographicBounds(in: linkTextRange)
                    {
                        addCursorRect(contentView.convert(linkTypographicBounds, to: self), cursor: cursorValue)
                    } else {
                        stop.pointee = true
                    }
                }
            }
        }
    }

    open override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()

        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            self.backgroundColor = self.backgroundColor

            self.updateSelectedRangeHighlight()
            self.updateSelectedLineHighlight()
            self.layoutGutter()
        }
    }

    open override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()

        if let scrollView {
            NotificationCenter.default.addObserver(self, selector: #selector(didLiveScrollNotification(_:)), name: NSScrollView.didLiveScrollNotification, object: scrollView)
        }
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if self.window != nil {
            // setup registerd plugins
            setupPlugins()
        }
    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)

        // click-through `contentView`, `contentViewportView`, `selectionView` subviews
        // that makes first responder properly redirect to main view
        // and ignore utility subviews that should remain transparent
        // for interaction.
        if let view = result, view != self,
           (view.isDescendant(of: contentView) || view.isDescendant(of: contentViewportView) || view.isDescendant(of: selectionView))
        {
            // Check if this is an attachment view - allow it to handle its own events
            if isTextAttachmentView(view) {
                return view
            }
            
            // For non-attachment views, proxy to text view
            return self
        }
        return result
    }
    
    private func isTextAttachmentView(_ view: NSView) -> Bool {
        // Walk up the view hierarchy to find if this view is part of an attachment
        var currentView: NSView? = view
        while let parentView = currentView?.superview {
            if let fragmentView = parentView as? STTextLayoutFragmentView {
                // Check if view is an attachment view
                for provider in fragmentView.layoutFragment.textAttachmentViewProviders {
                    if let attachmentView = provider.view {
                        if attachmentView == view || view.isDescendant(of: attachmentView) {
                            return true
                        }
                    }
                }
                break
            }
            currentView = parentView
        }
        return false
    }

    open override var canBecomeKeyView: Bool {
        super.canBecomeKeyView && acceptsFirstResponder && !isHiddenOrHasHiddenAncestor
    }

    open override var needsPanelToBecomeKey: Bool {
        isSelectable || isEditable
    }

    open override var acceptsFirstResponder: Bool {
        isSelectable
    }

    open override func becomeFirstResponder() -> Bool {
        if isEditable {
            dispatchPrecondition(condition: .onQueue(.main))
            NotificationCenter.default.post(name: NSText.didBeginEditingNotification, object: self, userInfo: nil)
        }

        defer {
            isFirstResponder = true
        }

        return super.becomeFirstResponder()
    }

    open override func resignFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didEndEditingNotification, object: self, userInfo: [NSText.didEndEditingNotification: NSTextMovement.other.rawValue])
        }

        defer {
            isFirstResponder = false
        }
        return super.resignFirstResponder()
    }

    /// Resigns the window’s key window status.
    ///
    /// Swift documentation to NSWindow.resignKey() is wrong about selector sent to the first responder.
    /// It uses resignKeyWindow(), not resignKey() selector.
    ///
    /// Never invoke this method directly.
    @objc private func resignKeyWindow() {
        updateInsertionPointStateAndRestartTimer()
    }

    @objc private func becomeKeyWindow() {
        updateInsertionPointStateAndRestartTimer()
    }

    open override var intrinsicContentSize: NSSize {
        // usageBoundsForTextContainer already includes lineFragmentPadding via STTextLayoutManager workaround
        let textSize = textLayoutManager.usageBoundsForTextContainer.size
        let gutterWidth = gutterView?.frame.width ?? 0
        
        return NSSize(
            width: textSize.width + gutterWidth,
            height: textSize.height
        )
    }

    open override class var isCompatibleWithResponsiveScrolling: Bool {
        false
    }

    open override func prepareContent(in rect: NSRect) {
        let oldPreparedContentRect = preparedContentRect

        var rect = rect

        // Expand content to the full width.
        // This affects viewport
        rect.size.width = max(rect.width, frame.width)

        super.prepareContent(in: rect)

        if !oldPreparedContentRect.isAlmostEqual(to: preparedContentRect) {
            // I'm pretty sure there is a TextKit2 issue with the processing layout synchronously.
            // It behaves as if it is always processed asynchronously in the background, and it can get clogged.
            // Until the background processing does not finish all the work, the values returned by the API is just bananas.
            // It automatically fixes itself after a while. I wish the API express how it works.
            // https://mastodon.social/@krzyzanowskim/115532735501211715
            layoutViewport()
        }
    }

    /// The current selection range of the text view.
    ///
    /// If the length of the selection range is 0, indicating that the selection is actually an insertion point
    public var textSelection: NSRange {
        set {
            setSelectedRange(newValue)
        }

        get {
            selectedRange()
        }
    }

    internal func setString(_ string: Any?) {
        undoManager?.disableUndoRegistration()
        defer {
            undoManager?.enableUndoRegistration()
        }

        switch string {
        case let string as String:
            replaceCharacters(in: textLayoutManager.documentRange, with: string, useTypingAttributes: true, allowsTypingCoalescing: false)
        case let attributedString as NSAttributedString:
            replaceCharacters(in: textLayoutManager.documentRange, with: attributedString, allowsTypingCoalescing: false)
        case .none:
            replaceCharacters(in: textLayoutManager.documentRange, with: "", useTypingAttributes: true, allowsTypingCoalescing: false)
        default:
            return assertionFailure()
        }

        textLayoutManager.ensureLayout(for: NSTextRange(location: textLayoutManager.documentRange.endLocation))
    }

    /// Sets the rendering attribute for the value and range you specify.
    ///
    /// Rendering attributes are used only for onscreen drawing and are not persistent in any way.
    /// Currently the only rendering attributes recognized are those that do not affect layout (colors, underlines, and so on).
    open func addRenderingAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }

        for attr in attrs {
            textLayoutManager.addRenderingAttribute(attr.key, value: attr.value, for: textRange)
        }

        needsLayout = true
    }

    /// Add attribute.
    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        addAttributes(attrs, range: range, updateLayout: true)
    }

    /// Add attribute.
    private func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool) {
        if let textContentStorage = textContentManager as? NSTextContentStorage,
           let textStorage = textContentStorage.textStorage
        {
            if textContentManager.hasEditingTransaction {
                textStorage.addAttributes(attrs, range: range)
            } else {
                textContentManager.performEditingTransaction {
                    textStorage.addAttributes(attrs, range: range)
                }
            }
        }

        if updateLayout, !textContentManager.hasEditingTransaction {
            needsLayout = true
        }
    }

    /// Add attribute.
    internal func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {
        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentManager))
        }

        if updateLayout, !textContentManager.hasEditingTransaction {
            needsLayout = true
        }
    }

    /// Set attributes.
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        setAttributes(attrs, range: range, updateLayout: true)
    }

    internal func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool = true) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        setAttributes(attrs, range: textRange, updateLayout: updateLayout)
    }

    /// Set attributes.
    internal func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.setAttributes(attrs, range: NSRange(range, in: textContentManager))
        }

        if updateLayout, !textContentManager.hasEditingTransaction {
            needsLayout = true
        }
    }

    /// Remove rendering attribute.
    open func removeRenderingAttribute(_ attribute: NSAttributedString.Key, range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }

        textLayoutManager.removeRenderingAttribute(attribute, for: textRange)

        needsLayout = true
    }

    /// Remove attributes.
    open func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange) {
        removeAttribute(attribute, range: range, updateLayout: true)
    }

    /// Remove attributes.
    internal func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange, updateLayout: Bool) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        removeAttribute(attribute, range: textRange, updateLayout: updateLayout)
    }

    /// Remove attributes.
    internal func removeAttribute(_ attribute: NSAttributedString.Key, range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.removeAttribute(attribute, range: NSRange(range, in: textContentManager))
        }

        if updateLayout, !textContentManager.hasEditingTransaction {
            needsLayout = true
        }
    }

    // Update selected line highlight layer
    internal func updateSelectedLineHighlight() {
        guard highlightSelectedLine,
              textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty,
              !textLayoutManager.insertionPointSelections.isEmpty
        else {
            // don't highlight when there's selection
            return
        }

        func layoutHighlightView(in frameRect: CGRect) {
            let highlightView = STLineHighlightView(frame: frameRect)
            highlightView.backgroundColor = selectedLineHighlightColor
            selectionView.addSubview(highlightView)
        }

        if textLayoutManager.documentRange.isEmpty {
            // - empty document has no layout fragments, nothing, it's empty and has to be handled explicitly.
            // - there's no layout fragment at the document endLocation (technically it's out of bounds), has to be handled explicitly.
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                layoutHighlightView(
                    in: CGRect(
                        origin: CGPoint(
                            x: selectionView.bounds.minX,
                            y: selectionFrame.origin.y
                        ),
                        size: CGSize(
                            width: selectionView.bounds.width,
                            height: typingLineHeight
                        )
                    ).pixelAligned
                )
            }
        } else if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            // build the rectangle out of fragments rectangles
            var combinedFragmentsRect: CGRect?
            
            // TODO some beutiful day:
            // Don't rely on NSTextParagraph.paragraphContentRange, but that
            // makes tricky to get all the conditions right (especially for last line)
            // Problem is that NSTextParagraph.rangeInElement span across two lines (eg. "abc\n" are two lines) while
            // paragraphContentRange is just one ("abc")
            //
            // Another idea here is to use `textLayoutManager.textLayoutFragment(for: selectionTextRange.location)`
            // to find the layout fragment and us its frame as highlight area. It has its issue when it comes to the
            // extra line fragment area (sic).
            textLayoutManager.enumerateTextLayoutFragments(in: viewportRange) { layoutFragment in
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement
                for textLineFragment in layoutFragment.textLineFragments {

                    let isLineSelected = STGutterCalculations.isLineSelected(
                        textLineFragment: textLineFragment,
                        layoutFragment: layoutFragment,
                        contentRangeInElement: contentRangeInElement,
                        textLayoutManager: textLayoutManager
                    )

                    if isLineSelected {
                        let lineSelectionRectangle: CGRect

                        if !textLineFragment.isExtraLineFragment {
                            var lineFragmentFrame = layoutFragment.layoutFragmentFrame
                            lineFragmentFrame.size.height = textLineFragment.typographicBounds.height

                            lineSelectionRectangle = CGRect(
                                origin: CGPoint(
                                    x: selectionView.bounds.minX,
                                    y: lineFragmentFrame.origin.y + textLineFragment.typographicBounds.minY
                                ),
                                size: CGSize(
                                    width: selectionView.bounds.width,
                                    height: lineFragmentFrame.height
                                )
                            )
                        } else {
                            // Workaround for FB15131180
                            let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                            var lineFragmentFrame = layoutFragment.layoutFragmentFrame
                            lineFragmentFrame.size.height = prevTextLineFragment.typographicBounds.height

                            lineSelectionRectangle = CGRect(
                                origin: CGPoint(
                                    x: selectionView.bounds.minX,
                                    y: lineFragmentFrame.origin.y + prevTextLineFragment.typographicBounds.maxY
                                ),
                                size: CGSize(
                                    width: selectionView.bounds.width,
                                    height: lineFragmentFrame.height
                                )
                            )
                        }

                        if let rect = combinedFragmentsRect {
                            combinedFragmentsRect = rect.union(lineSelectionRectangle)
                        } else {
                            combinedFragmentsRect = lineSelectionRectangle
                        }
                    }
                }
                return true
            }
            
            if let combinedFragmentsRect {
                layoutHighlightView(in: combinedFragmentsRect.pixelAligned)
            }
        }
    }

    // Update selection range highlight (on selectionView)
    internal func updateSelectedRangeHighlight() {
        guard !textLayoutManager.textSelections.isEmpty,
            let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange
        else {
            selectionView.subviews = []
            // don't highlight when there's selection
            return
        }

        if !selectionView.subviews.isEmpty {
            selectionView.subviews = []
        }

        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges).sorted(by: { $0.location < $1.location }).compactMap({ $0.clamped(to: viewportRange) }) {
            // NOTE: enumerateTextSegments is very slow https://github.com/krzyzanowskim/STTextView/discussions/25#discussioncomment-6464398
            //       Clamp enumerated range to viewport range
            textLayoutManager.enumerateTextSegments(in: textRange, type: .selection) {(_, textSegmentFrame, _, _) in

                let selectionFrame = textSegmentFrame.intersection(selectionView.frame).pixelAligned
                guard !selectionFrame.isNull else {
                    return true
                }

                if !selectionFrame.size.width.isZero {
                    let selectionHighlightView = STSelectionHighlightView(frame: selectionFrame)
                    selectionView.addSubview(selectionHighlightView)

                    // Remove insertion point when selection
                    removeInsertionPointView()
                } else {
                    // NOTE: this is to hide/show insertion point on selection.
                    //       there's probably better place to handle that.
                    updateInsertionPointStateAndRestartTimer()
                }

                return true // keep going
            }
        }
    }

    @objc internal func didLiveScrollNotification(_ notification: Notification) {
        cancelComplete(notification.object)
    }

    open override func viewDidUnhide() {
        super.viewDidUnhide()
        self.prepareContent(in: visibleRect) // layoutViewport() on change
    }

    open override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        layoutViewport()
    }

    open override func layout() {
        super.layout()

        layoutViewport()
        if needsScrollToSelection, let textRange = textLayoutManager.textSelections.last?.textRanges.last {
            scrollToVisible(textRange, type: .standard)
        }

        needsScrollToSelection = false
    }

    /// Resizes the receiver to fit its text.
    open func sizeToFit() {
        let gutterWidth = gutterView?.frame.width ?? 0

        let horizontalContentInset = scrollView?.contentInsets.horizontalInsets ?? 0

        // Need to configure TextContainer before layout calculations
        var newTextContainerSize = textContainer.size
        if !isHorizontallyResizable {
            // setup text container for wrap-text, need for layout
            // Subtract rightPadding so text wraps before the accessory view area
            // Only apply when we have valid geometry (visibleRect.width > 0)
            let baseWidth = visibleRect.width - gutterWidth
            let proposedContentWidth = visibleRect.width > 0 ? baseWidth - rightPadding : baseWidth
            if proposedContentWidth > 0 && !newTextContainerSize.width.isAlmostEqual(to: proposedContentWidth) {
                newTextContainerSize.width = proposedContentWidth
            }
        } else {
            newTextContainerSize.width = _defaultTextContainerSize.width
        }

        if !isVerticallyResizable {
            let proposedContentHeight = visibleRect.height
            if !newTextContainerSize.height.isAlmostEqual(to: proposedContentHeight) {
                newTextContainerSize.height = proposedContentHeight
            }
        } else {
            newTextContainerSize.height = _defaultTextContainerSize.height
        }

        if !textContainer.size.isAlmostEqual(to: newTextContainerSize) {
            textContainer.size = newTextContainerSize
            logger.debug("\(#function) pre-configure textContainer.size \(newTextContainerSize.debugDescription)")
        }
        
        // Now perform layout with correct container size
        // Estimate `usageBoundsForTextContainer` size is based on performed layout.
        // If layout didn't happen for the whole document, it only cover
        // the fragment that is known. And even after ensureLayout for the whole document
        // `textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)`
        // it can't report exact size (it must do internal estimations then).
        //
        // Because I use "lazy layout" with the viewport, there is no "layout everything"
        // on launch (due to performance reason) hence the total size is not know in advance.
        // TextKit estimate the usageBoundsForTextContainer until everything is layed out
        // that may result in weird and unexpected values along the way
        //
        // Calling ensureLayout on the whole document should fix the value, however
        // it may be time consuming (in seconds) hence not recommended:
        // textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
        //
        // Asking for the end location result in estimated `usageBoundsForTextContainer`
        // that eventually get right as more and more layout happen (when scrolling)

        // Estimated text container size to layout document
        // It is impossible to get the stable content size performantly: https://developer.apple.com/forums/thread/761364?answerId=799739022#799739022
        // textLayoutManager.ensureLayout(for: NSTextRange(location: textLayoutManager.documentRange.endLocation))
        var usageBoundsForTextContainerSize = textLayoutManager.usageBoundsForTextContainer.size
        let initialUsageBoundsHeight = usageBoundsForTextContainerSize.height

        // the enumerate seems to be faster than ensureLayout, but still estimated
        textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.endLocation, options: [.reverse, .ensuresLayout, .ensuresExtraLineFragment]) { layoutFragment in
            usageBoundsForTextContainerSize.height = layoutFragment.layoutFragmentFrame.maxY
            return false
        }

        // DON'T resize container, it trigger another layout()!

        // Adjust self.frame to match textContainer.size used for layout
        var newFrame = CGRect(origin: frame.origin, size: usageBoundsForTextContainerSize)
        if !isHorizontallyResizable {
            // wrap-text
            newFrame.size.width = textContainer.size.width
        } else if isHorizontallyResizable {
            // no wrap-text
            // limit width to fit the width of usage bounds
            newFrame.size.width = max(visibleRect.width - horizontalContentInset, usageBoundsForTextContainerSize.width - gutterWidth + textContainer.lineFragmentPadding)
        }

        if !isVerticallyResizable {
            // limit-text
            newFrame.size.height = usageBoundsForTextContainerSize.height
        } else if isVerticallyResizable {
            // expand
            // changes height to fit the height of its text
            newFrame.size.height = usageBoundsForTextContainerSize.height
        }

        newFrame = newFrame.pixelAligned

        // Skip resize when usageBoundsForTextContainer reports invalid height during text reset
        if initialUsageBoundsHeight < typingLineHeight && frame.height > visibleRect.height {
            return
        }

        // Add bottom padding for "scroll past end" behavior.
        // Added before comparison so we compare content+padding to content+padding,
        // avoiding repeated setFrameSize calls.
        if bottomPadding > 0 {
            newFrame.size.height += bottomPadding
        }

        // Add right padding for accessory views (e.g., annotation margins).
        // Only apply when we have valid geometry (visibleRect.width > 0).
        if rightPadding > 0 && visibleRect.width > 0 {
            newFrame.size.width += rightPadding
        }

        if !newFrame.size.isAlmostEqual(to: frame.size) {
            setFrameSize(newFrame.size) // layout()
        }
    }

    open override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)

        // contentView should always fill the entire STTextView
        contentView.frame.origin.x = gutterView?.frame.width ?? 0
        contentView.frame.size = newSize
    }

    internal func layoutViewport() {
        // not matter what, the layoutViewport() is slow
        textLayoutManager.textViewportLayoutController.layoutViewport()
    }

    open func scrollRangeToVisible(_ range: NSRange) {
        textFinderClient.scrollRangeToVisible(range)
    }

    open func scrollRangeToVisible(_ range: NSTextRange) {
        scrollRangeToVisible(NSRange(range, in: textContentManager))
    }

    open func textWillChange(_ sender: Any?) {
        if textFinder.isIncrementalSearchingEnabled {
            textFinder.noteClientStringWillChange()
        }

        let notification = Notification(name: Self.textWillChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegateProxy.textViewWillChangeText(notification)
    }

    /// Sends out necessary notifications when a text change completes.
    @available(*, deprecated, message: "Use didChangeText() instead")
    open func textDidChange(_ sender: Any?) {
        didChangeText()
    }

    internal func didChangeText(in textRange: NSTextRange) {
        didChangeText()
        textCheckingDidChangeText(in: NSRange(textRange, in: textContentManager))
    }

    /// Sends out necessary notifications when a text change completes.
    ///
    /// Invoked automatically at the end of a series of changes, this method posts an `textDidChangeNotification` to the default notification center, which also results in the delegate receiving `textViewDidChangeText(_:)` message.
    /// Subclasses implementing methods that change their text should invoke this method at the end of those methods.
    open func didChangeText() {

        let notification = Notification(name: STTextView.textDidChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegateProxy.textViewDidChangeText(notification)
        _yankingManager.textChanged()

        needsScrollToSelection = true
        needsDisplay = true
    }

    open func replaceCharacters(in range: NSRange, with string: String) {
        textFinderClient.replaceCharacters(in: range, with: string)
    }

    open func replaceCharacters(in range: NSRange, with string: NSAttributedString) {
        textFinderClient.replaceCharacters(in: range, with: string)
    }

    open func replaceCharacters(in range: NSTextRange, with string: String) {
        replaceCharacters(in: range, with: string, useTypingAttributes: true, allowsTypingCoalescing: false)
    }

    internal func replaceCharacters(in textRanges: [NSTextRange], with replacementString: String, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        self.replaceCharacters(
            in: textRanges,
            with: NSAttributedString(string: replacementString, attributes: useTypingAttributes ? typingAttributes : [:]),
            allowsTypingCoalescing: allowsTypingCoalescing
        )
    }

    internal func replaceCharacters(in textRanges: [NSTextRange], with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        // Replace from the end to beginning of the document
        for textRange in textRanges.sorted(by: { $0.location > $1.location }) {
            replaceCharacters(in: textRange, with: replacementString, allowsTypingCoalescing: allowsTypingCoalescing)
        }
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: String, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        self.replaceCharacters(
            in: textRange,
            with: NSAttributedString(string: replacementString, attributes: useTypingAttributes ? typingAttributes : [:]),
            allowsTypingCoalescing: allowsTypingCoalescing
        )
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        let previousStringInRange = (textContentManager as? NSTextContentStorage)!.attributedString!.attributedSubstring(from: NSRange(textRange, in: textContentManager))

        textWillChange(self)
        delegateProxy.textView(self, willChangeTextIn: textRange, replacementString: replacementString.string)

        textContentManager.performEditingTransaction {
            textContentManager.replaceContents(
                in: textRange,
                with: [NSTextParagraph(attributedString: replacementString)]
            )
        }

        delegateProxy.textView(self, didChangeTextIn: textRange, replacementString: replacementString.string)
        didChangeText(in: textRange)
        
        guard allowsUndo, let undoManager = undoManager, undoManager.isUndoRegistrationEnabled else { return }

        // Reach to NSTextStorage because NSTextContentStorage range extraction is cumbersome.
        // A range that is as long as replacement string, so when undo it undo
        let undoRange = NSTextRange(
            location: textRange.location,
            end: textContentManager.location(textRange.location, offsetBy: replacementString.length)
        ) ?? textRange

        if let coalescingUndoManager = undoManager as? CoalescingUndoManager, !undoManager.isUndoing, !undoManager.isRedoing {
            if allowsTypingCoalescing && processingKeyEvent {
               coalescingUndoManager.checkCoalescing(range: undoRange)
           } else {
               coalescingUndoManager.endCoalescing()
           }
        }
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { textView in
            // Regular undo action
            textView.replaceCharacters(
                in: undoRange,
                with: previousStringInRange,
                allowsTypingCoalescing: false
            )
            textView.setSelectedTextRange(textRange, updateLayout: true)
        }
        undoManager.endUndoGrouping()
    }

    /// Whenever text is to be changed due to some user-induced action,
    /// this method should be called with information on the change.
    /// Coalesce consecutive typing events
    open func shouldChangeText(in affectedTextRange: NSTextRange, replacementString: String?) -> Bool {
        let result = delegateProxy.textView(self, shouldChangeTextIn: affectedTextRange, replacementString: replacementString)
        if !result {
            return result
        }

        return result
    }

    internal func shouldChangeText(in affectedTextRanges: [NSTextRange], replacementString: String?) -> Bool {
        affectedTextRanges.allSatisfy { textRange in
            shouldChangeText(in: textRange, replacementString: replacementString)
        }
    }

    /// Informs the receiver that it should begin coalescing successive typing operations in a new undo grouping
    public func breakUndoCoalescing() {
        (undoManager as? CoalescingUndoManager)?.endCoalescing()
    }

    /// Releases the drag information still existing after the dragging session has completed.
    ///
    /// Subclasses may override this method to clean up any additional data structures used for dragging. In your overridden method, be sure to invoke super’s implementation of this method.
    open func cleanUpAfterDragOperation() {
        originalDragSelections = nil
    }

    open func addPlugin(_ instance: any STPlugin) {
        let plugin = Plugin(instance: instance)
        plugins.append(plugin)

        // setup plugin right away if view is already setup
        if self.window != nil {
            setupPlugins()
        }
    }

    private func setupPlugins() {
        for (offset, plugin) in plugins.enumerated() where plugin.events == nil {
            // set events handler
            var plugin = plugin
            plugin.events = setUp(instance: plugin.instance)
            plugins[offset] = plugin
        }
    }

    @MainActor
    private func setUp(instance: some STPlugin) -> STPluginEvents {
        // unwrap any STPluginProtocol
        let events = STPluginEvents()
        instance.setUp(
            context: STPluginContext(
                coordinator: instance.makeCoordinator(context: .init(textView: self)),
                textView: self,
                events: events
            )
        )
        return events
    }
}

// MARK: - NSViewInvalidating

private extension NSViewInvalidating where Self == STTextView.Invalidations.InsertionPoint {
    static var insertionPoint: STTextView.Invalidations.InsertionPoint {
        STTextView.Invalidations.InsertionPoint()
    }
}

private extension NSViewInvalidating where Self == STTextView.Invalidations.CursorRects {
    static var cursorRects: STTextView.Invalidations.CursorRects {
        STTextView.Invalidations.CursorRects()
    }
}

private extension NSViewInvalidating where Self == STTextView.Invalidations.LayoutViewport {
    static var layoutViewport: STTextView.Invalidations.LayoutViewport {
        STTextView.Invalidations.LayoutViewport()
    }
}

private extension STTextView.Invalidations {

    struct InsertionPoint: NSViewInvalidating {

        func invalidate(view: NSView) {
            guard let textView = view as? STTextView else {
                return
            }

            textView.updateInsertionPointStateAndRestartTimer()
        }
    }

    struct CursorRects: NSViewInvalidating {

        func invalidate(view: NSView) {
            view.window?.invalidateCursorRects(for: view)
        }
    }

    struct LayoutViewport: NSViewInvalidating {

        func invalidate(view: NSView) {
            guard let textView = view as? STTextView else {
                return
            }

            textView.layoutViewport()
        }
    }

}
