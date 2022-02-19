//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

private final class STTextContentView: NSView {
    override var isFlipped: Bool { true }
}

private final class STTextSelectionView: NSView {
    override var isFlipped: Bool { true }
}

@objc public protocol STTextViewDelegate: AnyObject {
    /// Any keyDown or paste which changes the contents causes this
    @objc optional func textDidChange(_ notification: Notification)
    /// Sent when the selection changes in the text view.
    @objc optional func textViewDidChangeSelection(_ notification: Notification)
    /// Sent when a text view needs to determine if text in a specified range should be changed.
    @objc optional func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool
}

final public class STTextView: NSView, STText {

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
        didSet {
            needsViewportLayout = true
        }
    }

    public var textColor: NSColor? {
        didSet {
            needsDisplay = true
        }
    }

    public var defaultParagraphStyle: NSParagraphStyle? {
        didSet {
            needsViewportLayout = true
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

    public weak var delegate: STTextViewDelegate?

    let textLayoutManager: NSTextLayoutManager
    let textContentStorage: NSTextContentStorage
    private let textContainer: NSTextContainer
    private let contentView: STTextContentView
    private let selectionView: STTextContentView
    private var fragmentViewMap: NSMapTable<NSTextLayoutFragment, NSView>

    var needsViewportLayout: Bool = false {
        didSet {
            if needsViewportLayout {
                needsLayout = true
            }
        }
    }
    
    public override var isFlipped: Bool { return true }

    private var scrollView: NSScrollView? {
        guard let result = enclosingScrollView else { return nil }
        if result.documentView == self {
            return result
        } else {
            return nil
        }
    }

    override init(frame frameRect: NSRect) {
        fragmentViewMap = .weakToWeakObjects()

        textContentStorage = NSTextContentStorage()
        textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: frameRect.height))
        textLayoutManager = NSTextLayoutManager()
        textLayoutManager.textContainer = textContainer
        textContentStorage.addTextLayoutManager(textLayoutManager)

        contentView = STTextContentView(frame: frameRect)
        selectionView = STTextContentView(frame: frameRect)

        isEditable = true
        isSelectable = true
        highlightSelectedLine = true

        super.init(frame: frameRect)

        // workaround for: the text selection highlight can remain between lines (2017-09 macOS 10.13).
        scaleUnitSquare(to: NSSize(width: 0.5, height: 0.5))
        scaleUnitSquare(to: convert(CGSize(width: 1, height: 1), from: nil)) // reset scale

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var acceptsFirstResponder: Bool {
        true
    }

    public override func becomeFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didBeginEditingNotification, object: self, userInfo: nil)
        }
        return true
    }

    public override func resignFirstResponder() -> Bool {
        if isEditable {
            NotificationCenter.default.post(name: NSText.didEndEditingNotification, object: self, userInfo: nil)
        }
        return true
    }

    public override class var isCompatibleWithResponsiveScrolling: Bool {
        true
    }

    public override func prepareContent(in rect: NSRect) {
        needsViewportLayout = true
        super.prepareContent(in: rect)
    }

    public override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
    }

    public override func draw(_ dirtyRect: NSRect) {
        drawBackground(in: dirtyRect)
        super.draw(dirtyRect)
    }

    public func drawBackground(in rect: NSRect) {
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

        switch string {
        case .none:
            if delegate?.textView?(self, shouldChangeTextIn: documentRange, replacementString: nil) ?? true {
                textContentStorage.textStorage = NSTextStorage()
                updateContentSizeIfNeeded()
                needsViewportLayout = true
                didChangeText()
            }
        case is String:
            var attributes: [NSAttributedString.Key: Any] = [:]
            if let paragraphStyle = defaultParagraphStyle {
                attributes[.paragraphStyle] = paragraphStyle
            }
            if let font = font {
                attributes[.font] = font
            }
            if let textColor = textColor {
                attributes[.foregroundColor] = textColor
            }
            if delegate?.textView?(self, shouldChangeTextIn: documentRange, replacementString: string as? String) ?? true {
                textContentStorage.textStorage = NSTextStorage(string: string as! String, attributes: attributes)
                updateContentSizeIfNeeded()
                needsViewportLayout = true
                didChangeText()
            }
        case is NSAttributedString:
            if delegate?.textView?(self, shouldChangeTextIn: documentRange, replacementString: (string as? NSAttributedString)?.string) ?? true {
                textContentStorage.textStorage = NSTextStorage(attributedString: string as! NSAttributedString)
                updateContentSizeIfNeeded()
                needsViewportLayout = true
                didChangeText()
            }
        default:
            assertionFailure()
            break
        }

        updateContentSizeIfNeeded()
        needsViewportLayout = true
    }

    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        textContentStorage.textStorage?.addAttributes(attrs, range: range)
    }

    public func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange) {
        textContentStorage.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentStorage))
    }

    private func updateContentSizeIfNeeded() {
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

    public override func setFrameSize(_ newSize: NSSize) {
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

    public override func layout() {
        super.layout()

        if needsViewportLayout {
            needsViewportLayout = false
            textLayoutManager.textViewportLayoutController.layoutViewport()
            updateContentSizeIfNeeded()
        }
    }

    public func didChangeText() {
        let notification = Notification(name: STTextView.didChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
        delegate?.textDidChange?(notification)
    }
}

extension STTextView {

    public override func mouseDown(with event: NSEvent) {
        if isSelectable {
            let point = convert(event.locationInWindow, from: nil)
            updateTextSelection(
                interactingAt: point,
                inContainerAt: textLayoutManager.documentRange.location,
                anchors: event.modifierFlags.contains(.shift) ? textLayoutManager.textSelections : [],
                extending: event.modifierFlags.contains(.shift),
                shouldScrollToVisible: false
            )
        }
    }

    public override func mouseDragged(with event: NSEvent) {
        if isSelectable {
            let point = convert(event.locationInWindow, from: nil)
            updateTextSelection(
                interactingAt: point,
                inContainerAt: textLayoutManager.documentRange.location,
                anchors: textLayoutManager.textSelections,
                extending: true,
                visual: event.modifierFlags.contains(.option),
                shouldScrollToVisible: true
            )
        }
    }

    public override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
    }
}

extension STTextView: NSTextLayoutManagerDelegate {

    // func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
    //    NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
    // }

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

    func updateSelectionHighlights() {
        guard !textLayoutManager.textSelections.isEmpty else { return }

        selectionView.subviews = []
        
        for textSelection in textLayoutManager.textSelections {
            for textRange in textSelection.textRanges {
                textLayoutManager.enumerateTextSegments(in: textRange, type: .highlight, options: []) {(textSegmentRange, textSegmentFrame, baselinePosition, textContainer) in
                    var highlightFrame = textSegmentFrame.intersection(frame)
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
