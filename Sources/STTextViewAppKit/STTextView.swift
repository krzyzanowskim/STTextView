//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//      |---selectionView
//      |---contentView
//              |---(STInsertionPointView | STTextLayoutFragmentView)
//      |---decorationView
//      |---gutterView
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
    @objc public var font: NSFont {
        get {
            _defaultTypingAttributes[.font] as! NSFont
        }

        set {
            _defaultTypingAttributes[.font] = newValue

            // apply to the document
            if !textLayoutManager.documentRange.isEmpty {
                addAttributes([.font: newValue], range: textLayoutManager.documentRange)
            }
        }
    }

    /// The text color of the text view.
    ///
    /// Default text color.
    @objc public var textColor: NSColor {
        get {
            _defaultTypingAttributes[.foregroundColor] as! NSColor
        }

        set {
            _defaultTypingAttributes[.foregroundColor] = newValue
        }
    }

    /// Default paragraph style.
    @objc public var defaultParagraphStyle: NSParagraphStyle {
        set {
            _defaultTypingAttributes[.paragraphStyle] = newValue
        }
        get {
            _defaultTypingAttributes[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
        }
    }

    /// Default typing attributes used in place of missing attributes of font, color and paragraph
    private var _defaultTypingAttributes: [NSAttributedString.Key: Any]

    /// The attributes to apply to new text that the user enters.
    ///
    /// This dictionary contains the attribute keys (and corresponding values) to apply to newly typed text.
    /// When the text view’s selection changes, the contents of the dictionary are reset automatically.
    @objc public internal(set) var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            _typingAttributes.merging(_defaultTypingAttributes) { (current, _) in current }
        }

        set {
            _typingAttributes = newValue
            needsDisplay = true
        }
    }

    private var _typingAttributes: [NSAttributedString.Key: Any]

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
        guard !textLayoutManager.documentRange.isEmpty else {
            return typingAttributes
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
        let lineHeightMultiple = paragraphStyle.lineHeightMultiple.isAlmostZero() ? 1.0 : paragraphStyle.lineHeightMultiple
        return calculateDefaultLineHeight(for: font) * lineHeightMultiple
    }

    /// The characters of the receiver’s text.
    ///
    /// For performance reasons, this value is the current backing store of the text object.
    /// If you want to maintain a snapshot of this as you manipulate the text storage, you should make a copy of the appropriate substring.
    @objc public var text: String? {
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
    @objc public var attributedText: NSAttributedString? {
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
                textContainer.size = NSTextContainer().size
                if let clipView = scrollView?.contentView as? NSClipView {
                    frame.size.width = clipView.bounds.size.width - clipView.contentInsets.horizontalInsets
                }
                needsLayout = true
                needsDisplay = true
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

                textContainer.size = NSTextContainer().size
                if let clipView = scrollView?.contentView as? NSClipView {
                    frame.size.height = clipView.bounds.size.height - clipView.contentInsets.verticalInsets
                }

                needsLayout = true
                needsDisplay = true
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
    @Invalidating(.display)
    @objc dynamic open var highlightSelectedLine: Bool = false

    /// Enable to show line numbers in the gutter.
    @Invalidating(.layout)
    open var showsLineNumbers: Bool = false {
        didSet {
            isGutterVisible = showsLineNumbers
        }
    }

    /// Gutter view
    public var gutterView: STGutterView?
    internal var scrollViewFrameObserver: NSKeyValueObservation?

    /// The highlight color of the selected line.
    ///
    /// Note: Needs ``highlightSelectedLine`` to be set to `true`
    @Invalidating(.display)
    @objc dynamic open var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)

    /// The background color of a text selection.
    @Invalidating(.display)
    @objc dynamic open var selectionBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor

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
    @objc open private(set) var textLayoutManager: NSTextLayoutManager

    @available(*, deprecated, renamed: "textContentManager")
    open var textContentStorage: NSTextContentStorage {
        textContentManager as! NSTextContentStorage
    }

    /// The text view's text storage object.
    @objc open private(set) var textContentManager: NSTextContentManager

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
    internal let contentView: ContentView

    /// Selection highlight content view.
    internal let selectionView: SelectionView

    /// Layout fragments decoration, custom rendering attributes
    internal let decorationView: DecorationView

    internal var fragmentViewMap: NSMapTable<NSTextLayoutFragment, STTextLayoutFragmentView>
    private var usageBoundsForTextContainerObserver: NSKeyValueObservation?

    internal lazy var speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()

    internal lazy var completionWindowController: STCompletionWindowController? = {
        let viewController = delegateProxy.textViewCompletionViewController(self)
        return STCompletionWindowController(viewController)
    }()

    /// Search-and-replace find interface inside a view.
    open private(set) var textFinder: NSTextFinder

    /// NSTextFinderClient
    internal let textFinderClient: STTextFinderClient

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
    @Invalidating(.layout)
    public var showsInvisibleCharacters: Bool = false {
        didSet {
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
        #if os(macOS)
        true
        #else
        false
        #endif
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

        contentView = ContentView()
        selectionView = SelectionView()
        decorationView = DecorationView(textLayoutManager: textLayoutManager)

        allowsUndo = true
        _undoManager = CoalescingUndoManager()

        textFinder = NSTextFinder()
        textFinderClient = STTextFinderClient()

        _defaultTypingAttributes = [
            .paragraphStyle: NSParagraphStyle.default,
            .font: NSFont.preferredFont(forTextStyle: .body),
            .foregroundColor: NSColor.textColor
        ]

        _typingAttributes = [:]

        super.init(frame: frameRect)

        textLayoutManager.delegate = self
        textFinderClient.textView = self
        textCheckingController = NSTextCheckingController(client: self)

        postsBoundsChangedNotifications = true
        postsFrameChangedNotifications = true

        wantsLayer = true
        autoresizingMask = [.width, .height]

        textLayoutManager.textViewportLayoutController.delegate = self

        addSubview(selectionView)
        addSubview(contentView)
        addSubview(decorationView)

        do {
            let recognizer = DragSelectedTextGestureRecognizer(target: self, action: #selector(_dragSelectedTextGestureRecognizer(gestureRecognizer:)))
            recognizer.minimumPressDuration = NSEvent.doubleClickInterval / 3
            recognizer.isEnabled = isSelectable
            addGestureRecognizer(recognizer)
        }

        // Forward didChangeSelectionNotification from STTextLayoutManager
        NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }

            _yankingManager.selectionChanged()

            let textViewNotification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: notification.userInfo)

            NotificationCenter.default.post(textViewNotification)
            self.delegateProxy.textViewDidChangeSelection(textViewNotification)

            NSAccessibility.post(element: self, notification: .selectedTextChanged)
            // textCheckingController.didChangeSelectedRange()
        }


        usageBoundsForTextContainerObserver = textLayoutManager.observe(\.usageBoundsForTextContainer, options: [.initial, .new]) { [weak self] textLayoutManager, change in
            // FB13291926: this notification no longer works
            self?.needsUpdateConstraints = true
        }
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

    open override func resetCursorRects() {
        super.resetCursorRects()

        let visibleRect = contentView.convert(contentView.visibleRect, to: self)
        if isSelectable, visibleRect != .zero {
            addCursorRect(visibleRect, cursor: .iBeam)

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
        self.updateSelectionHighlights()
    }

    open override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enclosingClipViewBoundsDidChange(_:)),
            name: NSClipView.boundsDidChangeNotification,
            object: scrollView?.contentView
        )
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if self.window != nil {
            textFinder.client = textFinderClient
            textFinder.findBarContainer = enclosingScrollView

            // setup registerd plugins
            setupPlugins()
        }

    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)

        // click-through `contentView`, `selectionView` and `decorationView` subviews
        // that makes first responder properly redirect to main view
        // and ignore utility subviews that should remain transparent
        // for interaction.
        if let view = result, view != self,
           (view.isDescendant(of: contentView) || view.isDescendant(of: selectionView) || view.isDescendant(of: decorationView))
        {
            return self
        }
        return result
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
        textLayoutManager.usageBoundsForTextContainer.size
    }

    open override class var isCompatibleWithResponsiveScrolling: Bool {
        true
    }

    open override func prepareContent(in rect: NSRect) {
        super.prepareContent(in: rect.inset(dy: -visibleRect.height / 2))
        layoutViewport()
    }

    /// The current selection range of the text view.
    ///
    /// If the length of the selection range is 0, indicating that the selection is actually an insertion point
    public var textSelection: NSRange? {
        set {
            if let newValue {
                self.setSelectedRange(newValue)
            }
        }

        get {
            return self.selectedRange()
        }
    }

    open override func draw(_ dirtyRect: NSRect) {
        drawBackground(in: dirtyRect)
        super.draw(dirtyRect)
    }

    /// Draws the background of the text view.
    open func drawBackground(in rect: NSRect) {
        guard highlightSelectedLine,
              textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty,
              !textLayoutManager.insertionPointSelections.isEmpty
        else {
            // don't highlight when there's selection
            return
        }

        drawHighlightedLine(in: rect)
    }

    private func drawHighlightedLine(in rect: NSRect) {

        func drawHighlight(in fillRect: CGRect) {
            guard let context = NSGraphicsContext.current?.cgContext else {
                return
            }

            context.saveGState()
            context.setFillColor(selectedLineHighlightColor.cgColor)
            context.fill(fillRect)
            context.restoreGState()
        }

        if textLayoutManager.documentRange.isEmpty {
            // - empty document has no layout fragments, nothing, it's empty and has to be handled explicitly.
            // - there's no layout fragment at the document endLocation (technically it's out of bounds), has to be handled explicitly.
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                drawHighlight(
                    in: CGRect(
                        origin: CGPoint(
                            x: convert(contentView.bounds, from: contentView).minX,
                            y: selectionFrame.origin.y
                        ),
                        size: CGSize(
                            width: max(scrollView?.contentSize.width ?? 0, contentView.bounds.width),
                            height: typingLineHeight
                        )
                    )
                )
            }
            return
        }

        guard let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return
        }

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
            for lineFragment in layoutFragment.textLineFragments {

                func isLineSelected() -> Bool {
                    textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
                        var result = true
                        if lineFragment.isExtraLineFragment {
                            let c1 = layoutFragment.rangeInElement.endLocation == selectionTextRange.location
                            result = result && c1
                        } else {
                            let c1 = contentRangeInElement.contains(selectionTextRange)
                            let c2 = contentRangeInElement.intersects(selectionTextRange)
                            let c3 = selectionTextRange.contains(contentRangeInElement)
                            let c4 = selectionTextRange.intersects(contentRangeInElement)
                            let c5 = contentRangeInElement.endLocation == selectionTextRange.location
                            result = result && (c1 || c2 || c3 || c4 || c5)
                        }
                        return partialResult && result
                    }
                }

                if isLineSelected() {
                    var lineFragmentFrame = layoutFragment.layoutFragmentFrame
                    lineFragmentFrame.size.height = lineFragment.typographicBounds.height


                    let r = CGRect(
                        origin: CGPoint(
                            x: convert(contentView.bounds, from: contentView).minX,
                            y: lineFragmentFrame.origin.y + lineFragment.typographicBounds.minY
                        ),
                        size: CGSize(
                            width: max(scrollView?.contentSize.width ?? 0, contentView.bounds.width),
                            height: lineFragmentFrame.height
                        )
                    )

                    if let rect = combinedFragmentsRect {
                        combinedFragmentsRect = rect.union(r)
                    } else {
                        combinedFragmentsRect = r
                    }
                }
            }
            return true
        }

        if let combinedFragmentsRect {
            drawHighlight(in: combinedFragmentsRect.pixelAligned)
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
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        addAttributes(attrs, range: range, updateLayout: true)
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    private func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        addAttributes(attrs, range: textRange, updateLayout: updateLayout)
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    internal func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {
        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentManager))
        }

        if updateLayout {
            updateTypingAttributes()
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

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    internal func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.setAttributes(attrs, range: NSRange(range, in: textContentManager))
        }


        if updateLayout {
            updateTypingAttributes()
            needsLayout = true
        }
    }

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    open func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange) {
        removeAttribute(attribute, range: range, updateLayout: true)
    }

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    internal func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange, updateLayout: Bool) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        removeAttribute(attribute, range: textRange, updateLayout: updateLayout)
    }

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    internal func removeAttribute(_ attribute: NSAttributedString.Key, range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.removeAttribute(attribute, range: NSRange(range, in: textContentManager))
        }

        updateTypingAttributes()

        if updateLayout {
            needsLayout = true
        }
    }

    internal func updateSelectionHighlights() {
        guard !textLayoutManager.textSelections.isEmpty,
            let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange
        else {
            selectionView.subviews.removeAll()
            return
        }

        if !selectionView.subviews.isEmpty {
            selectionView.subviews.removeAll()
        }

        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges).sorted(by: { $0.location < $1.location }).compactMap({ $0.clamped(to: viewportRange) }) {
            // NOTE: enumerateTextSegments is very slow https://github.com/krzyzanowskim/STTextView/discussions/25#discussioncomment-6464398
            //       Clamp enumerated range to viewport range
            textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: .rangeNotRequired) {(_, textSegmentFrame, _, _) in

                let selectionFrame = textSegmentFrame.intersection(frame).pixelAligned
                guard !selectionFrame.isNull else {
                    return true
                }

                if !selectionFrame.size.width.isZero {
                    let selectionHighlightView = SelectionHighlightView(frame: selectionFrame)
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

        // Update gutter selection
        layoutGutter()
    }

    // Update textContainer width to match textview width if track textview width
    // widthTracksTextView = true
    private func _configureTextContainerSize() {
        var containerSize = textContainer.size
        if !isHorizontallyResizable {
            containerSize.width = contentView.bounds.maxX // - _textContainerInset.width * 2
        }

        if !isVerticallyResizable {
            containerSize.height = contentView.bounds.height // - _textContainerInset.height * 2
        }

        if !textContainer.size.isAlmostEqual(to: containerSize)  {
            textContainer.size = containerSize
        }
    }

    open override func setFrameOrigin(_ newOrigin: NSPoint) {
        super.setFrameOrigin(newOrigin)
        _configureTextContainerSize()
    }

    open override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        _configureTextContainerSize()
    }

    @objc internal func enclosingClipViewBoundsDidChange(_ notification: Notification) {
        layoutGutter()
    }

    open override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        layoutViewport()
    }

    open override func layout() {
        super.layout()

        layoutViewport()

        let gutterPadding = gutterView?.bounds.width ?? 0
        let newContentFrame = CGRect(
            x: gutterPadding,
            y: frame.origin.y,
            // FIXME: something is wrong when this changes. Possible race with layoutViewport
            width: frame.width - gutterPadding,
            height: frame.height
        )

        if !newContentFrame.isAlmostEqual(to: contentView.frame) {
            contentView.frame = newContentFrame
            selectionView.frame = newContentFrame
            decorationView.frame = newContentFrame
        }

        if needsScrollToSelection, let textRange = textLayoutManager.textSelections.last?.textRanges.last {
            scrollToVisible(textRange, type: .standard)
        }
        
        needsScrollToSelection = false
    }

    /// Resizes the receiver to fit its text.
    open func sizeToFit() {
        _configureTextContainerSize()

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

        textLayoutManager.ensureLayout(for: NSTextRange(location: textLayoutManager.documentRange.endLocation))
        var size = textLayoutManager.usageBoundsForTextContainer.size

        // add textContainerInset at some point
        // size.width += textContainerInset.width * 2;
        // size.height += textContainerInset.height * 2;

        var horizontalInsets: CGFloat = 0
        var verticalInsets: CGFloat = 0
        if let clipView = scrollView?.contentView as? NSClipView {
            horizontalInsets = clipView.contentInsets.horizontalInsets
            verticalInsets = clipView.contentInsets.verticalInsets
        }

        if isHorizontallyResizable {
            size.width = max(frame.size.width - horizontalInsets, size.width)
        } else {
            size.width = frame.size.width - horizontalInsets
        }

        if isVerticallyResizable {
            // we should at least be the visible size if we're not in a clip view
            // however the `size` may be bananas (estimated) and enlarge too much
            // that going never going to shrink later.
            // It is expected that vertically height going to grow and shring (that does not apply to horizontally)
            //
            // size.height = max(frame.size.height - verticalInsets, size.height)
        } else {
            size.height = frame.size.height - verticalInsets
        }

        // if we're in a clip view we should at be at least as big as the clip view
        if let clipView = scrollView?.contentView as? NSClipView {

            if size.width < clipView.bounds.size.width - horizontalInsets {
                size.width = clipView.bounds.size.width - horizontalInsets
            }

            if size.height < clipView.bounds.size.height - verticalInsets {
                size.height = clipView.bounds.size.height - verticalInsets
            }

        }

        if !frame.size.isAlmostEqual(to: size) {
            self.setFrameSize(size)
        }
    }

    internal func layoutViewport() {
        // layoutViewport does not handle properly layout range
        // for far jump it tries to layout everything starting at location 0
        // even though viewport range is properly calculated.
        // No known workaround.
        textLayoutManager.textViewportLayoutController.layoutViewport()
    }

    @discardableResult
    internal func scrollToVisible(_ selectionTextRange: NSTextRange, type: NSTextLayoutManager.SegmentType) -> Bool {
        guard var rect = textLayoutManager.textSegmentFrame(in: selectionTextRange, type: type) else {
            return false
        }

        if rect.width.isZero {
            // add padding around the point to ensure the visibility the segment
            // since the width of the segment is 0 for a selection
            rect = rect.inset(by: .init(top: 0, left: -textContainer.lineFragmentPadding, bottom: 0, right: -textContainer.lineFragmentPadding))
        }

        return scrollToVisible(rect)
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
        needsScrollToSelection = true

        let notification = Notification(name: STTextView.textDidChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegateProxy.textViewDidChangeText(notification)
        _yankingManager.textChanged()

        needsDisplay = true
    }

    public func replaceCharacters(in range: NSRange, with string: String) {
        textFinderClient.replaceCharacters(in: range, with: string)
    }

    public func replaceCharacters(in range: NSTextRange, with string: String) {
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

private extension NSViewInvalidating where Self == NSView.Invalidations.InsertionPoint {
    static var insertionPoint: NSView.Invalidations.InsertionPoint {
        NSView.Invalidations.InsertionPoint()
    }
}

private extension NSViewInvalidating where Self == NSView.Invalidations.CursorRects {
    static var cursorRects: NSView.Invalidations.CursorRects {
        NSView.Invalidations.CursorRects()
    }
}

private extension NSView.Invalidations {

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

}
