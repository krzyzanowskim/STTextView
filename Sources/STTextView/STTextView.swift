//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//      |---selectionLayer (CALayer)
//      |---contentLayer (CALAyer)
//              |---(STInsertionPointLayer | TextLayoutFragmentLayer)
//
//

import Cocoa

open class STTextView: NSView, CALayerDelegate, NSTextInput {

    public static let didChangeNotification = NSText.didChangeNotification
    public static let didChangeSelectionNotification = NSTextView.didChangeSelectionNotification

    /// A Boolean value that controls whether the text view allow the user to edit text.
    open var isEditable: Bool {
        didSet {
            isSelectable = isEditable
        }
    }
    
    open var isSelectable: Bool {
        didSet {
            updateInsertionPointStateAndRestartTimer()
        }
    }

    open var shouldDrawInsertionPoint: Bool {
        isFirstResponder && isSelectable
    }

    open var insertionPointColor: NSColor

    public var font: NSFont? {
        get {
            typingAttributes[.font] as? NSFont
        }

        set {
            typingAttributes[.font] = newValue
            // TODO: update storage
        }
    }

    public var textColor: NSColor? {
        get {
            typingAttributes[.foregroundColor] as? NSColor
        }

        set {
            typingAttributes[.foregroundColor] = newValue
            // TODO: update storage
        }
    }

    public var defaultParagraphStyle: NSParagraphStyle? {
        get {
            typingAttributes[.paragraphStyle] as? NSParagraphStyle
        }

        set {
            typingAttributes[.paragraphStyle] = newValue
        }
    }

    public var typingAttributes: [NSAttributedString.Key: Any] {
        didSet {
            needsViewportLayout = true
            needsDisplay = true
        }
    }

    public var string: String? {
        set {
            setString(newValue)
        }
        get {
            textContentStorage.attributedString?.string
        }
    }

    public var documentRange: NSTextRange {
        textContentStorage.documentRange
    }

    /// A Boolean that controls whether the text container adjusts the width of its bounding rectangle when its text view resizes.
    ///
    /// When the value of this property is `true`, the text container adjusts its width when the width of its text view changes. The default value of this property is `false`.
    public var widthTracksTextView: Bool {
        set {
            textContainer.widthTracksTextView = newValue
        }
        get {
            textContainer.widthTracksTextView
        }
    }

    open var highlightSelectedLine: Bool {
        didSet {
            needsDisplay = true
        }
    }

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

    public weak var delegate: STTextViewDelegate?

    public let textLayoutManager: NSTextLayoutManager
    public let textContentStorage: NSTextContentStorage
    public let textContainer: NSTextContainer
    private let contentLayer: STCALayer
    internal let selectionLayer: STCALayer
    internal var backingScaleFactor: CGFloat {
        window?.backingScaleFactor ?? 1
    }
    private var fragmentLayerMap: NSMapTable<NSTextLayoutFragment, STCALayer>

    /// A Boolean value indicating whether the view needs scroll to visible selection pass before it can be drawn.
    internal var needScrollToSelection: Bool = false {
        didSet {
            if needScrollToSelection {
                needsLayout = true
            }
        }
    }

    /// A Boolean value indicating whether the view needs a viewport layout pass before it can be drawn
    public var needsViewportLayout: Bool = false {
        didSet {
            if needsViewportLayout {
                needsLayout = true
            }
        }
    }
    
    public override var isFlipped: Bool {
        true
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

    override public init(frame frameRect: NSRect) {
        fragmentLayerMap = .weakToWeakObjects()

        textContentStorage = STTextContentStorage()
        textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: frameRect.height))
        textLayoutManager = STTextLayoutManager()
        textLayoutManager.textContainer = textContainer
        textContentStorage.addTextLayoutManager(textLayoutManager)

        contentLayer = STCALayer(frame: frameRect)
        contentLayer.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]
        selectionLayer = STCALayer(frame: frameRect)
        selectionLayer.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]

        isEditable = true
        isSelectable = isEditable
        insertionPointColor = .textColor
        highlightSelectedLine = false
        typingAttributes = [.paragraphStyle: NSParagraphStyle.default, .foregroundColor: NSColor.textColor]
        allowsUndo = true
        _undoManager = CoalescingUndoManager<TypingTextUndo>()
        isFirstResponder = false

        super.init(frame: frameRect)

        // Set insert point at the very beginning
        setSelectedRange(NSTextRange(location: documentRange.location))

        postsBoundsChangedNotifications = true
        postsFrameChangedNotifications = true

        wantsLayer = true
        autoresizingMask = [.width, .height]

        textLayoutManager.textViewportLayoutController.delegate = self

        layer?.addSublayer(selectionLayer)
        layer?.addSublayer(contentLayer)

        NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }

            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
            self.delegate?.textViewDidChangeSelection?(notification)
        }

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
    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)

        // click-through `contentView` and `selectionView` subviews
        // that makes first responder properly redirect to main view
        // and ignore utility subviews that should remain transparent
        // for interaction.
        if let view = result, view != self, (view.layer!.isDescendant(of: contentLayer) || view.layer!.isDescendant(of: selectionLayer)) {
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
        needsViewportLayout = true
        super.prepareContent(in: rect)
    }

    open override func draw(_ dirtyRect: NSRect) {
        drawBackground(in: dirtyRect)
        super.draw(dirtyRect)
    }

    open func drawBackground(in rect: NSRect) {
        if highlightSelectedLine {
            drawHighlightedLine(in: rect)
        }
    }

    private func drawHighlightedLine(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let caretLocation = textLayoutManager.insertionPointLocation
        else {
            return
        }

        textLayoutManager.enumerateTextSegments(in: NSTextRange(location: caretLocation), type: .highlight) { segmentRange, textSegmentFrame, baselinePosition, textContainer -> Bool in
            // because `textLayoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresExtraLineFragment, .ensuresLayout, .estimatesSize])`
            // returns unexpected value for extra line fragment height (return 14) that is not correct in the context,
            // therefore for empty override height with value manually calculated from font + paragraph style
            var selectionFrame: NSRect = textSegmentFrame
            if segmentRange == documentRange {
                if let font = typingAttributes[.font] as? NSFont {
                    let paragraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
                    let lineHeight = NSLayoutManager().defaultLineHeight(for: font) * paragraphStyle.lineHeightMultiple
                    selectionFrame = NSRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: lineHeight))
                }
            }

            context.saveGState()
            context.setFillColor(NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25).cgColor)

            let fillRect = CGRect(
                origin: CGPoint(
                    x: 0,
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
        let documentRange = NSRange(textContentStorage.documentRange, in: textContentStorage)
        if case .some(let string) = string {
            switch string {
            case is NSAttributedString:
                insertText(string as! NSAttributedString, replacementRange: documentRange)
            case is String:
                insertText(NSAttributedString(string: string as! String, attributes: typingAttributes), replacementRange: documentRange)
            default:
                assertionFailure()
                return
            }
        } else if case .none = string {
            insertText("", replacementRange: documentRange)
        }
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.addAttributes(attrs, range: range)
        }
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentStorage))
        }

        if updateLayout {
            needsViewportLayout = true
        }
    }

    public func setSelectedRange(_ textRange: NSTextRange, updateLayout: Bool = true) {
        textLayoutManager.textSelections = [
            NSTextSelection(range: textRange, affinity: .downstream, granularity: .character)
        ]

        if updateLayout {
            needsViewportLayout = true
        }
    }

    internal func updateContentSizeIfNeeded() {
        let currentHeight = bounds.height
        var height: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.endLocation, options: [.reverse, .ensuresLayout]) { layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY
            return false // stop
        }

        let currentWidth = bounds.width
        var width: CGFloat = scrollView?.bounds.width ?? bounds.width

        // TODO: if offset didn't change since last time, it is not necessary to relayout
        if textContainer.widthTracksTextView == false, let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            // not necessarly need to layout whole thing, is's enough to enumerate over visible area
            textLayoutManager.enumerateTextLayoutFragments(from: viewportRange.location, options: .ensuresLayout) { layoutFragment in
                width = max(width, layoutFragment.layoutFragmentFrame.maxX)
                return layoutFragment.rangeInElement.intersects(viewportRange)
            }
        }

        height = max(height, scrollView?.contentSize.height ?? 0)
        width = max(width, scrollView?.contentSize.width ?? 0)
        if abs(currentHeight - height) > 1e-10 || abs(currentWidth - width) > 1e-10 {
            let contentSize = NSSize(width: width, height: height)
            setFrameSize(contentSize)
        }
    }

    open override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        adjustViewportOffsetIfNeeded()
        updateContentSizeIfNeeded()
    }

    open override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateTextContainerSizeIfNeeded()
        needsViewportLayout = true
    }

    private func updateTextContainerSizeIfNeeded() {
        guard let textContainer = textLayoutManager.textContainer,
              textContainer.widthTracksTextView,
              textContainer.size.width != bounds.width
        else {
            return
        }

        textContainer.size = NSSize(width: bounds.size.width, height: 0)
        needsViewportLayout = true
    }

    open override func layout() {
        super.layout()

        var shouldLayoutViewport = false

        if needsViewportLayout {
            needsViewportLayout = false
            shouldLayoutViewport = true
        }

        if needScrollToSelection {
            needScrollToSelection = false
            if let textSelection = textLayoutManager.textSelections.first {
                scrollToSelection(textSelection)
                shouldLayoutViewport = true
            }
        }

        if shouldLayoutViewport {
            textLayoutManager.textViewportLayoutController.layoutViewport()
            updateContentSizeIfNeeded()
        }
    }

    internal func scrollToSelection(_ selection: NSTextSelection) {
        guard let selectionTextRange = selection.textRanges.first else {
            return
        }

        if selectionTextRange.isEmpty {
            if let selectionRect = textLayoutManager.textSegmentRect(at: selectionTextRange.location) {
                scrollToVisible(selectionRect)
            }
        } else {
            switch selection.affinity {
            case .upstream:
                if let selectionRect = textLayoutManager.textSegmentRect(at: selectionTextRange.location) {
                    scrollToVisible(selectionRect)
                }
            case .downstream:
                if let location = textLayoutManager.location(selectionTextRange.endLocation, offsetBy: -1),
                   let selectionRect = textLayoutManager.textSegmentRect(at: location)
                {
                    scrollToVisible(selectionRect)
                }
            @unknown default:
                break
            }
        }
    }

    open func didChangeText() {
        needScrollToSelection = true
        needsDisplay = true

        let notification = Notification(name: STTextView.didChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegate?.textDidChange?(notification)
    }

    open func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString) {
        // NSTextDidBeginEditingNotification
        let nsrange = NSRange(textRange, in: textContentStorage)
        textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: replacementString)

        if let undoManager = undoManager as? CoalescingUndoManager<TypingTextUndo>, undoManager.isUndoing == false {
            // Add undo

            // An event is considered a typing event
            // if it is a keyboard event and the event's characters
            // match our replacement string.
            let isTyping: Bool
            if let event = NSApp.currentEvent, event.type == .keyDown, event.characters == replacementString.string {
                isTyping = true
            } else {
                isTyping = false
            }

            if allowsUndo, undoManager.isUndoRegistrationEnabled {
                if isTyping, textRange.isEmpty,
                   let coalescingValue = undoManager.coalescing?.value,
                   textRange.location == coalescingValue.textRange.endLocation,
                   let endLocation = textLayoutManager.location(textRange.location, offsetBy: replacementString.string.count ),
                   let range = NSTextRange(location: coalescingValue.textRange.location, end: endLocation)
                {
                    // update or extend existing range
                    undoManager.coalesce(
                        TypingTextUndo(
                            textRange: range,
                            value: replacementString
                        )
                    )

                    return
                } else {
                    // reset undo range
                    if undoManager.isCoalescing {
                        if let coalescingAction = undoManager.coalescing?.action,
                           let coalescingValue = undoManager.coalescing?.value {

                            // put coalesed undo on the stack
                            undoManager.setActionName("Typing")
                            undoManager.registerUndo(withTarget: self) { target in
                                coalescingAction(coalescingValue)
                            }

                            undoManager.breakUndoCoalescing()
                        }
                    }
                }
            }

            if isTyping, allowsUndo, undoManager.isUndoRegistrationEnabled {
                let undoRange: NSTextRange

                // The length of the undoRange is the length of the replacement, if any.
                if let endLocation = textLayoutManager.location(textRange.location, offsetBy: replacementString.string.count),
                   let range = NSTextRange(location: textRange.location, end: endLocation)
                {
                    undoRange = range
                } else {
                    undoRange = textRange
                }

                if !undoManager.isCoalescing {
                    // It fits here,
                    // yet it start implicit nested group that screw undo stack without following regular undo action
                    //
                    // undoManager.setActionName("Typing")

                    undoManager.registerCoalescingUndo(withTarget: self) { target, value in
                        // Replace with empty string
                        target.replaceCharacters(in: value.textRange, with: NSAttributedString())
                        target.didChangeText()
                    }

                    undoManager.coalesce(
                        TypingTextUndo(
                            textRange: undoRange,
                            value: replacementString
                        )
                    )
                }
            }
        }
    }

    open func replaceCharacters(in textRange: NSTextRange, with replacementString: String) {
        //let nsrange = NSRange(textRange, in: textContentStorage)
        //textContentStorage.textStorage?.replaceCharacters(in: nsrange, with: replacementString)
        replaceCharacters(in: textRange, with: NSAttributedString(string: replacementString, attributes: typingAttributes))
        delegate?.textView?(self, didChangeTextIn: textRange, replacementString: replacementString)
    }

    /// Whenever text is to be changed due to some user-induced action,
    /// this method should be called with information on the change.
    /// Coalesce consecutive typing events
    open func shouldChangeText(in affectedTextRange: NSTextRange, replacementString: String?) -> Bool {
        if !isEditable {
            return false
        }

        let result = delegate?.textView?(self, shouldChangeTextIn: affectedTextRange, replacementString: replacementString) ?? true
        if !result {
            return result
        }

        return result
    }

    public func breakUndoCoalescing() {
        (undoManager as? CoalescingUndoManager<TypingTextUndo>)?.breakUndoCoalescing()
    }
}

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        let overdrawRect = preparedContentRect
        let visibleRect = self.visibleRect
        var minY: CGFloat = 0
        var maxY: CGFloat = 0
        if overdrawRect.intersects(visibleRect) {
            // Use preparedContentRect for vertical overdraw and ensure visibleRect is included at the minimum,
            // the width is always bounds width for proper line wrapping.
            minY = min(overdrawRect.minY, max(visibleRect.minY, 0))
            maxY = max(overdrawRect.maxY, visibleRect.maxY)
        } else {
            // We use visible rect directly if preparedContentRect does not intersect.
            // This can happen if overdraw has not caught up with scrolling yet, such as before the first layout.
            minY = visibleRect.minY
            maxY = visibleRect.maxY
        }
        return CGRect(x: bounds.minX, y: minY, width: bounds.width, height: maxY - minY)
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        contentLayer.sublayers = nil
        CATransaction.begin()
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        CATransaction.commit()
        updateSelectionHighlights()
        adjustViewportOffsetIfNeeded()
    }

    internal func updateSelectionHighlights() {
        guard !textLayoutManager.textSelections.isEmpty else {
            selectionLayer.sublayers = nil
            return
        }

        selectionLayer.sublayers = nil

        for textRange in textLayoutManager.textSelections.flatMap(\.textRanges) {
            textLayoutManager.enumerateTextSegments(in: textRange, type: .selection, options: [.rangeNotRequired]) {(_, textSegmentFrame, baselinePosition, textContainer) in
                let highlightFrame = textSegmentFrame.intersection(frame).pixelAligned
                guard !highlightFrame.isNull else {
                    return true
                }

                if highlightFrame.size.width > 0 {
                    let highlightLayer = STCALayer(frame: highlightFrame)
                    highlightLayer.contentsScale = backingScaleFactor
                    highlightLayer.backgroundColor = NSColor.selectedTextBackgroundColor.cgColor
                    selectionLayer.addSublayer(highlightLayer)
                } else {
                    updateInsertionPointStateAndRestartTimer()
                }

                return true // keep going
            }
        }
    }

    private func adjustViewportOffsetIfNeeded() {

        guard let scrollView = scrollView else { return }

        func adjustViewportOffset() {
            let viewportLayoutController = textLayoutManager.textViewportLayoutController
            var layoutYPoint: CGFloat = 0
            textLayoutManager.enumerateTextLayoutFragments(from: viewportLayoutController.viewportRange!.location, options: [.reverse, .ensuresLayout]) { layoutFragment in
                layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
                return true
            }

            if !layoutYPoint.isZero {
                let adjustmentDelta = bounds.minY - layoutYPoint
                viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
                scroll(CGPoint(x: scrollView.contentView.bounds.minX, y: scrollView.contentView.bounds.minY + adjustmentDelta))
            }
        }

        let viewportLayoutController = textLayoutManager.textViewportLayoutController
        let contentOffset = scrollView.contentView.bounds.minY
        if contentOffset < scrollView.contentView.bounds.height &&
            viewportLayoutController.viewportRange!.location > textLayoutManager.documentRange.location {
            // Nearing top, see if we need to adjust and make room above.
            adjustViewportOffset()
        } else if viewportLayoutController.viewportRange!.location == textLayoutManager.documentRange.location {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        if let fragmentLayer = fragmentLayerMap.object(forKey: textLayoutFragment) as? TextLayoutFragmentLayer {
            let oldFrame = fragmentLayer.frame
            fragmentLayer.updateGeometry()
            if oldFrame != fragmentLayer.frame {
                fragmentLayer.needsDisplay()
            }
            contentLayer.addSublayer(fragmentLayer)
        } else {
            let fragmentLayer = TextLayoutFragmentLayer(layoutFragment: textLayoutFragment)
            fragmentLayer.updateGeometry()
            fragmentLayer.contentsScale = backingScaleFactor
            contentLayer.addSublayer(fragmentLayer)
            fragmentLayerMap.setObject(fragmentLayer, forKey: textLayoutFragment)
        }
    }
}

private extension CALayer {

    func isDescendant(of layer: CALayer) -> Bool {
        while let parent = layer.superlayer {
            if parent == layer {
                return true
            }
        }

        return false
    }
}
