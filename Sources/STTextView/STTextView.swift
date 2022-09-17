//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//      |---selectionLayer (STCATiledLayer)
//      |---contentLayer (STCATiledLayer)
//              |---(STInsertionPointLayer (STCALayer) | STTextLayoutFragmentLayer (STCALayer))
//      |---lineAnnotationLayer (STCATiledLayer)
//
//

import Cocoa

/// A TextKit2 text view without NSTextView baggage
open class STTextView: NSView, CALayerDelegate, NSTextInput {

    public static let willChangeNotification = NSNotification.Name("NSTextWillChangeNotification")
    public static let didChangeNotification = NSText.didChangeNotification
    public static let didChangeSelectionNotification = NSTextView.didChangeSelectionNotification

    /// Returns the type of layer used by the receiver.
    open var insertionPointLayerClass = STInsertionPointLayer.self

    /// A Boolean value that controls whether the text view allows the user to edit text.
    open var isEditable: Bool {
        didSet {
            isSelectable = isEditable
        }
    }

    /// A Boolean value that controls whether the text views allows the user to select text.
    open var isSelectable: Bool {
        didSet {
            updateInsertionPointStateAndRestartTimer()
        }
    }

    /// A Boolean value that determines whether the text view should draw its insertion point.
    open var shouldDrawInsertionPoint: Bool {
        isFirstResponder && isSelectable
    }

    /// The color of the insertion point.
    open var insertionPointColor: NSColor

    /// The width of the insertion point.
    open var insertionPointWidth: CGFloat = 1.0

    /// The font of the text view.
    public var font: NSFont? {
        get {
            typingAttributes[.font] as? NSFont
        }

        set {
            typingAttributes[.font] = newValue
            // TODO: update storage
        }
    }

    /// The text color of the text view.
    public var textColor: NSColor? {
        get {
            typingAttributes[.foregroundColor] as? NSColor
        }

        set {
            typingAttributes[.foregroundColor] = newValue
            // TODO: update storage
        }
    }

    /// The text view’s default paragraph style.
    public var defaultParagraphStyle: NSParagraphStyle? {
        get {
            typingAttributes[.paragraphStyle] as? NSParagraphStyle
        }

        set {
            typingAttributes[.paragraphStyle] = newValue
        }
    }

    /// The text view's typing attributes
    public var typingAttributes: [NSAttributedString.Key: Any] {
        didSet {
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The ``textContentStorage``'s string content.
    public var string: String {
        set {
            let prevLocation = textLayoutManager.textSelections.first?.textRanges.first?.location

            setString(newValue)

            // restore selection location
            setSelectedRange(NSTextRange(location: prevLocation ?? textLayoutManager.documentRange.location))
        }
        get {
            textContentStorage.attributedString?.string ?? ""
        }
    }

    /// A Boolean that controls whether the text container adjusts the width of its bounding rectangle when its text view resizes.
    ///
    /// When the value of this property is `true`, the text container adjusts its width when the width of its text view changes. The default value of this property is `false`.
    public var widthTracksTextView: Bool {
        set {
            if textContainer.widthTracksTextView != newValue {
                textContainer.widthTracksTextView = newValue

                if newValue == true {
                    textContainer.size = CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: CGFloat(Float.greatestFiniteMagnitude))
                } else {
                    textContainer.size = CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: CGFloat(Float.greatestFiniteMagnitude))
                }

                if let scrollView = scrollView {
                    setFrameSize(scrollView.contentSize)
                }
                
                needsLayout = true
                needsDisplay = true
            }
        }
        get {
            textContainer.widthTracksTextView
        }
    }

    /// A Boolean that controls whether the text view highlights the currently selected line.
    open var highlightSelectedLine: Bool {
        didSet {
            needsDisplay = true
        }
    }

    /// The highlight color of the selected line.
    ///
    /// Note: Needs ``highlightSelectedLine`` to be set to `true`
    public var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)

    /// The background color of a text selection.
    public var selectionBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor

    /// The text view's background color
    public var backgroundColor: NSColor? {
        didSet {
            layer?.backgroundColor = backgroundColor?.cgColor
        }
    }

    /// A Boolean value that indicates whether the receiver allows undo.
    ///
    /// `true` if the receiver allows undo, otherwise `false`. Default `true`.
    open var allowsUndo: Bool
    internal var _undoManager: UndoManager?


    /// A flag
    internal var processingKeyEvent: Bool = false

    /// The delegate for all text views sharing the same layout manager.
    public weak var delegate: STTextViewDelegate?

    /// The manager that lays out text for the text view's text container.
    public let textLayoutManager: NSTextLayoutManager

    /// The text view's text storage object.
    public let textContentStorage: NSTextContentStorage

    /// The text view's text container
    public let textContainer: NSTextContainer

    internal let contentLayer: STCATiledLayer
    internal let selectionLayer: STCATiledLayer
    internal var backingScaleFactor: CGFloat { window?.backingScaleFactor ?? 1 }
    internal var fragmentLayerMap: NSMapTable<NSTextLayoutFragment, STCALayer>

    internal lazy var completionWindowController: CompletionWindowController = {
        let viewController = delegate?.textViewCompletionViewController(self) ?? STCompletionViewController()
        return CompletionWindowController(viewController)
    }()

    /// Text line annotation views
    public var annotations: [STLineAnnotation] = [] {
        didSet {
            updateLineAnnotations()
        }
    }

    public let textFinder: NSTextFinder
    internal let textFinderClient: STTextFinderClient

    /// A Boolean value indicating whether the view needs scroll to visible selection pass before it can be drawn.
    internal var needScrollToSelection: Bool = false {
        didSet {
            if needScrollToSelection {
                needsLayout = true
            }
        }
    }

    public override var isFlipped: Bool {
        true
    }

    /// Generates and returns a scroll view with a STTextView set as its document view.
    public static func scrollableTextView() -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = STTextView()

        let textContainer = textView.textContainer
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        return scrollView
    }

    internal var scrollView: NSScrollView? {
        guard let result = enclosingScrollView else { return nil }
        if result.documentView == self {
            return result
        } else {
            return nil
        }
    }

    open override class var defaultMenu: NSMenu? {
        let menu = super.defaultMenu ?? NSMenu()
        menu.items = [
            NSMenuItem(title: NSLocalizedString("Cut", comment: ""), action: #selector(cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: NSLocalizedString("Copy", comment: ""), action: #selector(copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: NSLocalizedString("Paste", comment: ""), action: #selector(paste(_:)), keyEquivalent: "v")
        ]
        return menu
    }

    /// Initializes a text view.
    /// - Parameter frameRect: The frame rectangle of the text view.
    override public init(frame frameRect: NSRect) {
        fragmentLayerMap = .weakToWeakObjects()

        textContentStorage = STTextContentStorage()
        textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: CGFloat(Float.greatestFiniteMagnitude)))
        textLayoutManager = STTextLayoutManager()
        textLayoutManager.textContainer = textContainer
        textContentStorage.addTextLayoutManager(textLayoutManager)

        contentLayer = STCATiledLayer()
        contentLayer.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]
        selectionLayer = STCATiledLayer()
        selectionLayer.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]

        isEditable = true
        isSelectable = isEditable
        insertionPointColor = .textColor
        highlightSelectedLine = false
        typingAttributes = [.paragraphStyle: NSParagraphStyle.default, .foregroundColor: NSColor.textColor]
        allowsUndo = true
        _undoManager = CoalescingUndoManager<TypingTextUndo>()
        isFirstResponder = false

        textFinder = NSTextFinder()
        textFinderClient = STTextFinderClient()

        super.init(frame: frameRect)

        textFinderClient.textView = self

        // Set insert point at the very beginning
        setSelectedRange(NSTextRange(location: textContentStorage.documentRange.location))

        postsBoundsChangedNotifications = true
        postsFrameChangedNotifications = true

        wantsLayer = true
        autoresizingMask = [.width, .height]

        textLayoutManager.textViewportLayoutController.delegate = self

        layer?.addSublayer(selectionLayer)
        layer?.addSublayer(contentLayer)

        NotificationCenter.default.addObserver(forName: STTextView.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }

            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
            self.delegate?.textViewDidChangeSelection(notification)
        }

        delegate?.textView(self, didMoveCaretTo: 0, column: 0)
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        func updateContentScale(for layer: CALayer, scale: CGFloat) {
            layer.contentsScale = backingScaleFactor
            layer.setNeedsDisplay()
            for sublayer in layer.sublayers ?? [] {
                updateContentScale(for: sublayer, scale: scale)
            }
        }

        updateContentScale(for: contentLayer, scale: backingScaleFactor)
        updateContentScale(for: selectionLayer, scale: backingScaleFactor)

        textFinder.client = textFinderClient
        textFinder.findBarContainer = scrollView
    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)

        // click-through `contentLayer`, `selectionLayer` and `lineAnnotationLayer` sublayers
        // that makes first responder properly redirect to main view
        // and ignore utility subviews that should remain transparent
        // for interaction.
        if let view = result, view != self, let viewLayer = view.layer,
           (viewLayer.isDescendant(of: contentLayer) || viewLayer.isDescendant(of: selectionLayer)) {
            return self
        }
        return result
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var canBecomeKeyView: Bool {
        acceptsFirstResponder
    }

    open override var needsPanelToBecomeKey: Bool {
        isSelectable || isEditable
    }

    open override var acceptsFirstResponder: Bool {
        isSelectable
    }

    internal var isFirstResponder: Bool {
        didSet {
            updateInsertionPointStateAndRestartTimer()
        }
    }

    open override func becomeFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didBeginEditingNotification, object: self, userInfo: nil)
        }
        isFirstResponder = true
        return true
    }

    open override func resignFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didEndEditingNotification, object: self, userInfo: nil)
        }
        isFirstResponder = false
        return true
    }

    open override class var isCompatibleWithResponsiveScrolling: Bool {
        true
    }

    open override func prepareContent(in rect: NSRect) {
        needsLayout = true
        super.prepareContent(in: rect)
    }

    open override func draw(_ dirtyRect: NSRect) {
        drawBackground(in: dirtyRect)
        super.draw(dirtyRect)
    }

    /// Draws the background of the text view.
    open func drawBackground(in rect: NSRect) {
        if highlightSelectedLine {
            drawHighlightedLine(in: rect)
        }
    }

    private func getCaretPosition(inText: String, nsTextLocation: NSTextLocation) {
        var row = 0
        var col = 0

        guard let carretPosStr = textLayoutManager.insertionPointLocation?.description as? String,
              let carretPos = Int.init(carretPosStr)
        else {
            Log.info("Failed to get position")
            return
        }

        /// Create the range
        let range = NSRange.init(location: 0, length: carretPos)

        // Get only the text before the caret
        guard let txtStr = textContentStorage.documentString[range] else {
            fatalError("Failed to get caret position in document")
        }

        /// Split newlines
        let splitValue = txtStr.components(separatedBy: "\n")

        // Check on what row we are
        row = splitValue.count

        if !splitValue.isEmpty {
            // We are > row 0, so count with the correct row
            // splitValue[row - 1], is the row contents.
            // .utf8.count gives us the (current) length of the string
            col = splitValue[row - 1].utf8.count
        } else {
            // .count gives us the (current) length of the string
            col = txtStr.count
        }

        // Update value to delegate
        delegate?.textView(self, didMoveCaretTo: row, column: col)
    }

    private func drawHighlightedLine(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let caretLocation = textLayoutManager.insertionPointLocation
        else {
            return
        }

        getCaretPosition(
            inText: textContentStorage.documentString,
            nsTextLocation: caretLocation
        )

        textLayoutManager.enumerateTextSegments(in: NSTextRange(location: caretLocation), type: .highlight) { segmentRange, textSegmentFrame, baselinePosition, textContainer -> Bool in
            // because `textLayoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresExtraLineFragment, .ensuresLayout, .estimatesSize])`
            // returns unexpected value for extra line fragment height (return 14) that is not correct in the context,
            // therefore for empty override height with value manually calculated from font + paragraph style
            var selectionFrame: NSRect = textSegmentFrame
            if segmentRange == textContentStorage.documentRange {
                if let font = typingAttributes[.font] as? NSFont {
                    let paragraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
                    let lineHeight = NSLayoutManager().defaultLineHeight(for: font) * paragraphStyle.lineHeightMultiple
                    selectionFrame = NSRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: lineHeight))
                }
            }

            context.saveGState()
            context.setFillColor(selectedLineHighlightColor.cgColor)

            let fillRect = CGRect(
                origin: CGPoint(
                    x: bounds.minX,
                    y: selectionFrame.origin.y
                ),
                size: CGSize(
                    width: textContainer.size.width,
                    height: selectionFrame.height
                )
            )

            context.fill(fillRect)
            context.restoreGState()
            return false
        }
    }

    private func setString(_ string: Any?) {
        undoManager?.disableUndoRegistration()
        defer {
            undoManager?.enableUndoRegistration()
        }
        let documentNSRange = NSRange(textContentStorage.documentRange, in: textContentStorage)
        if case .some(let string) = string {
            switch string {
            case is NSAttributedString:
                insertText(string as! NSAttributedString, replacementRange: documentNSRange)
            case is String:
                insertText(NSAttributedString(string: string as! String, attributes: typingAttributes), replacementRange: documentNSRange)
            default:
                assertionFailure()
                return
            }
        } else if case .none = string {
            insertText("", replacementRange: documentNSRange)
        }
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool = true) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.addAttributes(attrs, range: range)
        }

        if updateLayout {
            needsLayout = true
        }
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentStorage))
        }

        if updateLayout {
            needsLayout = true
        }
    }

    public func setSelectedRange(_ textRange: NSTextRange, updateLayout: Bool = true) {
        textLayoutManager.textSelections = [
            NSTextSelection(range: textRange, affinity: .downstream, granularity: .character)
        ]

        if updateLayout {
            needsLayout = true
        }
    }

    internal func updateSelectionHighlights() {
        guard !textLayoutManager.textSelections.isEmpty else {
            selectionLayer.sublayers = nil
            return
        }

        selectionLayer.sublayers = nil

        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
            textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: .rangeNotRequired) {(_, textSegmentFrame, _, _) in
                let highlightFrame = textSegmentFrame.intersection(frame).pixelAligned
                guard !highlightFrame.isNull else {
                    return true
                }

                if highlightFrame.size.width > 0 {
                    let highlightLayer = STCALayer(frame: highlightFrame)
                    highlightLayer.contentsScale = backingScaleFactor
                    highlightLayer.backgroundColor = selectionBackgroundColor.cgColor
                    selectionLayer.addSublayer(highlightLayer)
                } else {
                    updateInsertionPointStateAndRestartTimer()
                }

                return true // keep going
            }
        }
    }

    // Update text view frame size
    internal func updateFrameSizeIfNeeded() {
        let currentSize = frame.size

        var proposedHeight: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.endLocation, options: [.reverse, .ensuresLayout, .ensuresExtraLineFragment]) { layoutFragment in
            proposedHeight = max(proposedHeight, layoutFragment.layoutFragmentFrame.maxY)
            return false // stop
        }

        var proposedWidth: CGFloat = 0
        if !textContainer.widthTracksTextView {
            // TODO: if offset didn't change since last time, it is not necessary to relayout
            // not necessarly need to layout whole thing, is's enough to enumerate over visible area
            let startLocation = textLayoutManager.textViewportLayoutController.viewportRange?.location ?? textLayoutManager.documentRange.location
            let endLocation = textLayoutManager.textViewportLayoutController.viewportRange?.endLocation ?? textLayoutManager.documentRange.endLocation
            textLayoutManager.enumerateTextLayoutFragments(from: startLocation, options: .ensuresLayout) { layoutFragment in
                proposedWidth = max(proposedWidth, layoutFragment.layoutFragmentFrame.maxX)
                return layoutFragment.rangeInElement.location < endLocation
            }
        } else {
            proposedWidth = currentSize.width
        }

        let proposedSize = CGSize(width: proposedWidth, height: proposedHeight)

        if !currentSize.isAlmostEqual(to: proposedSize) {
            setFrameSize(proposedSize)
        }
    }

    // Update textContainer width to match textview width if track textview width
    private func updateTextContainerSizeIfNeeded() {
        var proposedSize = textContainer.size

        if textContainer.widthTracksTextView, !textContainer.size.width.isAlmostEqual(to: bounds.width) {
            proposedSize.width = bounds.width
        }

        if textContainer.heightTracksTextView, !textContainer.size.height.isAlmostEqual(to: bounds.height)  {
            proposedSize.height = bounds.height
        }

        if textContainer.size != proposedSize {
            textContainer.size = proposedSize
            needsLayout = true
        }
    }

    open override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateTextContainerSizeIfNeeded()
    }

    open override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        adjustViewportOffsetIfNeeded()
        updateTextContainerSizeIfNeeded()
    }

    private func tile() {

        // Update clipView to accomodate vertical ruler
        if let scrollView = scrollView,
           scrollView.hasVerticalRuler,
           let verticalRulerView = scrollView.verticalRulerView
        {
            let clipView = scrollView.contentView
            clipView.automaticallyAdjustsContentInsets = false
            clipView.contentInsets = NSEdgeInsets(
                top: clipView.contentInsets.top,
                left: 0, // reset content inset
                bottom: clipView.contentInsets.bottom,
                right: clipView.contentInsets.right
            )

            scrollView.contentView.frame = CGRect(
                x: scrollView.bounds.origin.x + verticalRulerView.frame.width,
                y: scrollView.bounds.origin.y,
                width: scrollView.bounds.size.width - verticalRulerView.frame.width,
                height: scrollView.bounds.size.height
            )
        }

    }

    open override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        tile()
    }

    open override func layout() {
        super.layout()

        textLayoutManager.textViewportLayoutController.layoutViewport()

        if needScrollToSelection {
            needScrollToSelection = false
            if let textSelection = textLayoutManager.textSelections.first {
                scrollToSelection(textSelection)
                textLayoutManager.textViewportLayoutController.layoutViewport()
            }
        }
    }

    open override func viewWillDraw() {
        super.viewWillDraw()

        // deferred layout of line annotations
        updateLineAnnotations()
    }

    internal func scrollToSelection(_ selection: NSTextSelection) {
        guard let selectionTextRange = selection.textRanges.first else {
            return
        }

        if selectionTextRange.isEmpty {
            if let selectionRect = textLayoutManager.textSelectionSegmentFrame(at: selectionTextRange.location, type: .selection) {
                scrollToVisible(selectionRect)
            }
        } else {
            switch selection.affinity {
            case .upstream:
                if let selectionRect = textLayoutManager.textSelectionSegmentFrame(at: selectionTextRange.location, type: .selection) {
                    scrollToVisible(selectionRect)
                }
            case .downstream:
                if let location = textLayoutManager.location(selectionTextRange.endLocation, offsetBy: -1),
                   let selectionRect = textLayoutManager.textSelectionSegmentFrame(at: location, type: .selection)
                {
                    scrollToVisible(selectionRect)
                }
            @unknown default:
                break
            }
        }
    }

    open func willChangeText() {
        if textFinder.isIncrementalSearchingEnabled {
            textFinder.noteClientStringWillChange()
        }

        let notification = Notification(name: STTextView.willChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegate?.textWillChange(notification)
    }

    open func didChangeText() {
        needScrollToSelection = true

        let notification = Notification(name: STTextView.didChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        needsDisplay = true
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        if allowsUndo, let undoManager = undoManager {
            // typing coalescing
            if processingKeyEvent, allowsTypingCoalescing,
               let undoManager = undoManager as? CoalescingUndoManager<TypingTextUndo>
            {
                if undoManager.isCoalescing {
                    // Extend existing coalesce range
                    if let coalescingValue = undoManager.coalescing?.value,
                       textRange.location == coalescingValue.textRange.endLocation,
                       let undoEndLocation = textContentStorage.location(textRange.location, offsetBy: replacementString.string.count),
                       let undoTextRange = NSTextRange(location: coalescingValue.textRange.location, end: undoEndLocation)
                    {
                        undoManager.coalesce(TypingTextUndo(
                            textRange: undoTextRange,
                            attribugedString: NSAttributedString()
                        ))
                        
                    } else {
                        breakUndoCoalescing()
                    }
                }

                if !undoManager.isCoalescing {
                    let undoRange = NSTextRange(
                        location: textRange.location,
                        end: textContentStorage.location(textRange.location, offsetBy: replacementString.string.count)
                    ) ?? textRange

                    let previousStringInRange = textContentStorage.textStorage!.attributedSubstring(from: NSRange(textRange, in: textContentStorage))

                    let startTypingUndo = TypingTextUndo(
                        textRange: undoRange,
                        attribugedString: previousStringInRange
                    )

                    undoManager.startCoalescing(startTypingUndo, withTarget: self) { textView, typingTextUndo in
                        // Undo coalesced session action
                        textView.willChangeText()

                        textView.replaceCharacters(
                            in: typingTextUndo.textRange,
                            with: typingTextUndo.attribugedString ?? NSAttributedString(),
                            useTypingAttributes: false,
                            allowsTypingCoalescing: false
                        )

                        textView.didChangeText()
                    }
                }
            } else {
                breakUndoCoalescing()

                // Reach to NSTextStorage because NSTextContentStorage range extraction is cumbersome.
                // A range that is as long as replacement string, so when undo it undo
                let undoRange = NSTextRange(
                    location: textRange.location,
                    end: textContentStorage.location(textRange.location, offsetBy: replacementString.string.count)
                ) ?? textRange

                let previousStringInRange = textContentStorage.textStorage!.attributedSubstring(from: NSRange(textRange, in: textContentStorage))

                // Register undo/redo
                // I can't control internal redoStack, and coalescing messes up with the state
                // resulting in broken undo/redo availability
                undoManager.registerUndo(withTarget: self) { textView in
                    // Regular undo action
                    textView.willChangeText()

                    textView.replaceCharacters(
                        in: undoRange,
                        with: previousStringInRange,
                        useTypingAttributes: false,
                        allowsTypingCoalescing: false
                    )

                    textView.didChangeText()
                }
            }
        }

        delegate?.textView(self, willChangeTextIn: textRange, replacementString: replacementString.string)

        textContentStorage.textStorage?.replaceCharacters(
            in: NSRange(textRange, in: textContentStorage),
            with: replacementString
        )

        delegate?.textView(self, didChangeTextIn: textRange, replacementString: replacementString.string)
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: String, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        replaceCharacters(in: textRange, with: NSAttributedString(string: replacementString, attributes: typingAttributes), useTypingAttributes: useTypingAttributes, allowsTypingCoalescing: allowsTypingCoalescing)
    }

    open func replaceCharacters(in textRange: NSTextRange, with replacementString: String) {
        self.replaceCharacters(in: textRange, with: replacementString, useTypingAttributes: true, allowsTypingCoalescing: true)
    }

    /// Whenever text is to be changed due to some user-induced action,
    /// this method should be called with information on the change.
    /// Coalesce consecutive typing events
    open func shouldChangeText(in affectedTextRange: NSTextRange, replacementString: String?) -> Bool {
        if !isEditable {
            return false
        }

        let result = delegate?.textView(self, shouldChangeTextIn: affectedTextRange, replacementString: replacementString) ?? true
        if !result {
            return result
        }

        return result
    }

    public func breakUndoCoalescing() {
        (undoManager as? CoalescingUndoManager<TypingTextUndo>)?.breakCoalescing()
    }
}

private extension CALayer {

    func isDescendant(of layer: CALayer) -> Bool {
        var layer = layer
        while let parent = layer.superlayer {
            if parent == layer {
                return true
            }
            layer = parent
        }

        return false
    }
}
