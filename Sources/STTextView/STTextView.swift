//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

private final class STTextContentView: NSView {
    override var isFlipped: Bool {
        true
    }
}

private final class STTextSelectionView: NSView {
    override var isFlipped: Bool { true }
}

open class STTextView: NSView, STText, NSTextInput {

    public static let didChangeNotification = NSText.didChangeNotification
    public static let didChangeSelectionNotification = NSTextView.didChangeSelectionNotification

    /// A Boolean value that controls whether the text view allow the user to edit text.
    public var isEditable: Bool {
        didSet {
            isSelectable = isEditable
        }
    }
    
    public var isSelectable: Bool

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

    public var widthTracksTextView: Bool {
        set {
            textContainer.widthTracksTextView = newValue
        }
        get {
            textContainer.widthTracksTextView
        }
    }

    public var highlightSelectedLine: Bool {
        didSet {
            needsDisplay = true
        }
    }

    public var backgroundColor: NSColor? {
        didSet {
            layer?.backgroundColor = backgroundColor?.cgColor
        }
    }

    public weak var delegate: STTextViewDelegate?

    public let textLayoutManager: NSTextLayoutManager
    public let textContentStorage: NSTextContentStorage
    public let textContainer: NSTextContainer
    private let contentView: STTextContentView
    private let selectionView: STTextContentView
    private var fragmentViewMap: NSMapTable<NSTextLayoutFragment, NSView>

    internal var needScrollToSelection: Bool = false {
        didSet {
            if needScrollToSelection {
                needsLayout = true
            }
        }
    }

    internal var needsViewportLayout: Bool = false {
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

    override public init(frame frameRect: NSRect) {
        fragmentViewMap = .weakToWeakObjects()

        textContentStorage = STTextContentStorage()
        textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: frameRect.height))
        textLayoutManager = STTextLayoutManager()
        textLayoutManager.textContainer = textContainer
        textContentStorage.addTextLayoutManager(textLayoutManager)

        contentView = STTextContentView(frame: frameRect)
        selectionView = STTextContentView(frame: frameRect)

        isEditable = true
        isSelectable = true
        highlightSelectedLine = false
        typingAttributes = [.paragraphStyle: NSParagraphStyle.default, .foregroundColor: NSColor.textColor]

        super.init(frame: frameRect)

        // workaround for: the text selection highlight can remain between lines (2017-09 macOS 10.13).
        // scaleUnitSquare(to: NSSize(width: 0.5, height: 0.5))
        // scaleUnitSquare(to: convert(CGSize(width: 1, height: 1), from: nil)) // reset scale

        postsBoundsChangedNotifications = true
        postsFrameChangedNotifications = true

        wantsLayer = true
        autoresizingMask = [.width, .height]

        textLayoutManager.delegate = self
        textLayoutManager.textViewportLayoutController.delegate = self

        selectionView.wantsLayer = true
        selectionView.autoresizingMask = [.width, .height]
        addSubview(selectionView)

        contentView.wantsLayer = true
        contentView.autoresizingMask = [.width, .height]

        addSubview(contentView)

        NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: nil) { [weak self] notification in
            guard let self = self else { return }

            let notification = Notification(name: STTextView.didChangeSelectionNotification, object: self, userInfo: nil)
            NotificationCenter.default.post(notification)
            self.delegate?.textViewDidChangeSelection?(notification)
        }

    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        // click-through `contentView` and `selectionView` subviews
        // that makes first responder properly redirect to main view
        // and ignore utility subviews that should remain transparent
        // for interaction.
        if let view = result, view != self, (view.isDescendant(of: contentView) || view.isDescendant(of: selectionView)) {
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

    open override func becomeFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didBeginEditingNotification, object: self, userInfo: nil)
        }
        return true
    }

    open override func resignFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didEndEditingNotification, object: self, userInfo: nil)
        }
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

        var fragment = textLayoutManager.textLayoutFragment(for: caretLocation)
        var textLineFragment = fragment?.textLineFragment(at: caretLocation)

        if fragment == nil, let lastLocation = textLayoutManager.location(textLayoutManager.documentRange.endLocation, offsetBy: -1) {
            fragment = textLayoutManager.textLayoutFragment(for: lastLocation)
            if fragment?.hasExtraLineFragment == true {
                textLineFragment = fragment?.textLineFragments.last // aka extra line fragment
            } else {
                textLineFragment = fragment?.textLineFragments.first
            }
        }

        if let fragment = fragment, let textLineFragment = textLineFragment {
            context.saveGState()
            context.setFillColor(NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25).cgColor)

            let fillRect = CGRect(
                origin: fragment.layoutFragmentFrame.origin.applying(
                    .init(translationX: textLineFragment.typographicBounds.origin.x, y: textLineFragment.typographicBounds.origin.y)
                ),
                size: CGSize(
                    width: frame.width,
                    height: textLineFragment.typographicBounds.height
                )
            )
                .insetBy(dx: textContainer.lineFragmentPadding, dy: 0)

            context.fill(fillRect)
            context.restoreGState()
        }
    }

    private func setString(_ string: Any?) {
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

    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.addAttributes(attrs, range: range)
        }
    }

    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange) {
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentStorage))
        }
    }

    public func setSelectedRange(_ textRange: NSTextRange) {
        textLayoutManager.textSelections = [
            NSTextSelection(range: textRange, affinity: .downstream, granularity: .character)
        ]
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

        if needsViewportLayout {
            needsViewportLayout = false
            textLayoutManager.textViewportLayoutController.layoutViewport()
            updateContentSizeIfNeeded()
        }

        if needScrollToSelection {
            needScrollToSelection = false
            if let textSelection = textLayoutManager.textSelections.first {
                scrollToSelection(textSelection)
                textLayoutManager.textViewportLayoutController.layoutViewport()
                updateContentSizeIfNeeded()
            }
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

    public func didChangeText() {
        needScrollToSelection = true
        needsDisplay = true

        let notification = Notification(name: STTextView.didChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegate?.textDidChange?(notification)
    }
}

extension STTextView: NSTextLayoutManagerDelegate {
    //
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
        contentView.subviews = []
        CATransaction.begin()
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        CATransaction.commit()
        updateSelectionHighlights()
        adjustViewportOffsetIfNeeded()
    }

    internal func updateSelectionHighlights() {
        guard !textLayoutManager.textSelections.isEmpty else {
            selectionView.subviews = []
            return
        }

        selectionView.subviews = []

        for textSelection in textLayoutManager.textSelections {
            for textRange in textSelection.textRanges {
                textLayoutManager.enumerateTextSegments(in: textRange, type: .highlight, options: []) {(textSegmentRange, textSegmentFrame, baselinePosition, textContainer) in
                    var highlightFrame = textSegmentFrame.intersection(frame)
                    guard !highlightFrame.isNull else {
                        return true
                    }

                    let highlight = STTextSelectionView()
                    highlight.wantsLayer = true

                    if highlightFrame.size.width > 0 {
                        highlight.layer?.backgroundColor = NSColor.selectedTextBackgroundColor.cgColor
                    } else {
                        highlightFrame.size.width = 1 // fatten up the cursor
                        highlight.layer?.backgroundColor = NSColor.black.cgColor
                    }

                    highlight.frame = highlightFrame
                    selectionView.addSubview(highlight)
                    return true // keep going
                }
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
            viewportLayoutController.viewportRange!.location.compare(textLayoutManager.documentRange.location) == .orderedDescending {
            // Nearing top, see if we need to adjust and make room above.
            adjustViewportOffset()
        } else if viewportLayoutController.viewportRange!.location.compare(textLayoutManager.documentRange.location) == .orderedSame {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        if let fragmentView = fragmentViewMap.object(forKey: textLayoutFragment) as? TextLayoutFragmentView {
            let oldFrame = fragmentView.frame
            fragmentView.updateGeometry()
            if oldFrame != fragmentView.frame {
                fragmentView.needsDisplay = true
            }
            contentView.addSubview(fragmentView)
        } else {
            let fragmentView = TextLayoutFragmentView(layoutFragment: textLayoutFragment)
            contentView.addSubview(fragmentView)
            fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
        }
    }
}
