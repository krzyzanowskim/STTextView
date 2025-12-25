//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//  STGutterView
//      |- NSVisualEffectView
//      |- STGutterContainerView
//      |- STGutterSeparatorView
//          |-STGutterLineNumberCell
//      |- STGutterMarkerContainerView
//          |-STGutterMarker.view

import AppKit
import STTextViewCommon

public protocol STGutterViewDelegate: AnyObject {
    func textViewGutterShouldAddMarker(_ gutter: STGutterView) -> Bool
    func textViewGutterShouldRemoveMarker(_ gutter: STGutterView) -> Bool
}

public extension STGutterViewDelegate {
    func textViewGutterShouldAddMarker(_ gutter: STGutterView) -> Bool {
        true
    }

    func textViewGutterShouldRemoveMarker(_ gutter: STGutterView) -> Bool {
        true
    }
}

/// A gutter to the side of a scroll view’s document view.
open class STGutterView: NSView, NSDraggingSource {
    let separatorView: STGutterSeparatorView
    let containerView: STGutterContainerView
    let markerContainerView: STGutterMarkerContainerView

    private var _draggingMarker: STGutterMarker?
    private var _isDragging = false
    private var _didMouseDownAddMarker = false

    /// Delegate
    weak var delegate: (any STGutterViewDelegate)?

    /// The font used to draw line numbers.
    ///
    /// Initialized with a textView font value and does not update automatically when
    /// text view font changes.
    @Invalidating(.display)
    open var font = adjustGutterFont(NSFont(descriptor: NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.condensed), size: 0)!)

    /// The insets of the ruler view.
    @Invalidating(.display)
    open var insets = STRulerInsets(leading: 4.0, trailing: 6.0)

    /// Minimum thickness.
    @Invalidating(.layout)
    open var minimumThickness: CGFloat = 35

    /// The text color of the line numbers.
    @Invalidating(.display)
    open var textColor = NSColor.secondaryLabelColor

    /// A Boolean indicating whether to draw a separator or not. Default true.
    open var drawSeparator: Bool {
        get {
            separatorView.drawSeparator
        }
        set {
            separatorView.drawSeparator = newValue
        }
    }

    /// A Boolean that controls whether the text view highlights the currently selected line. Default false.
    @MainActor @Invalidating(.display)
    open var highlightSelectedLine = false

    @Invalidating(.display, .background)
    var backgroundColor: NSColor? = nil {
        didSet {
            layer?.backgroundColor = backgroundColor?.cgColor
            if backgroundColor == nil, _backgroundEffectView == nil {
                let backgroundEffect = NSVisualEffectView(frame: bounds)
                backgroundEffect.autoresizingMask = [.width, .height]
                backgroundEffect.blendingMode = .withinWindow
                backgroundEffect.material = .contentBackground
                backgroundEffect.state = .followsWindowActiveState
                // insert subview to `self`. below other subviews.
                self.subviews.insert(backgroundEffect, at: 0)
                self._backgroundEffectView = backgroundEffect
            } else if backgroundColor != nil, _backgroundEffectView != nil {
                _backgroundEffectView?.removeFromSuperview()
            }
        }
    }

    private var _backgroundEffectView: NSVisualEffectView?

    /// The background color of the highlighted line.
    @Invalidating(.display)
    open var selectedLineHighlightColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)

    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    open var selectedLineTextColor: NSColor? = nil

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    open var separatorColor: NSColor {
        get {
            separatorView.separatorColor
        }
        set {
            separatorView.separatorColor = newValue
        }
    }

    /// The receiver’s gutter markers to markers, removing any existing ruler markers and not consulting with the client view about the new markers.
    @Invalidating(.markers)
    private(set) var markers: [STGutterMarker] = []

    /// A Boolean value that determines whether the markers functionality is in an enabled state. Default `false.`
    open var areMarkersEnabled = false

    override public var isOpaque: Bool {
        false
    }

    override open var isFlipped: Bool {
        true
    }

    override open var allowsVibrancy: Bool {
        true
    }

    override public func makeBackingLayer() -> CALayer {
        CATiledLayer()
    }

    override public func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        nil
    }

    override init(frame: CGRect) {
        separatorView = STGutterSeparatorView(frame: frame)
        separatorView.autoresizingMask = [.width, .height]

        containerView = STGutterContainerView(frame: frame)
        containerView.autoresizingMask = [.width, .height]

        markerContainerView = STGutterMarkerContainerView(frame: frame)
        markerContainerView.autoresizingMask = [.width, .height]

        super.init(frame: frame)
        wantsLayer = true
        clipsToBounds = true

        // Add marker container first so it's behind line numbers
        addSubview(markerContainerView)
        addSubview(containerView)
        addSubview(separatorView)

        updateBackgroundColor()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            updateBackgroundColor()
        }
    }

    override open func layout() {
        super.layout()

        // Workaround
        // FB21059465: NSScrollView horizontal floating subview does not respect insets
        // https://gist.github.com/krzyzanowskim/d2c5d41b86096ccb19b110cf7a5514c8
        if let enclosingScrollView = superview?.superview as? NSScrollView, enclosingScrollView.automaticallyAdjustsContentInsets {
            let topContentInset = enclosingScrollView.contentView.contentInsets.top
            if !topContentInset.isAlmostZero(), !topContentInset.isAlmostEqual(to: -topContentInset) {
                self.frame.origin.y = -topContentInset
            }
        }
    }

    fileprivate func updateBackgroundColor() {
        self.backgroundColor = backgroundColor
    }

    public func addMarker(_ marker: STGutterMarker) {
        if self.marker(lineNumber: marker.lineNumber) == nil {
            markers.append(marker)
        }
    }

    public func removeMarker(lineNumber: Int) {
        markers.removeAll(where: { $0.lineNumber == lineNumber })
    }

    public func marker(lineNumber: Int) -> STGutterMarker? {
        markers.first { marker in
            marker.lineNumber == lineNumber
        }
    }

    func layoutMarkers() {
        for v in markerContainerView.subviews {
            v.removeFromSuperviewWithoutNeedingDisplay()
        }

        for marker in markers {
            let lineNumberCell = containerView.subviews
                .compactMap { $0 as? STGutterLineNumberCell }
                .first { $0.lineNumber == marker.lineNumber }

            if let lineNumberCell {
                marker.view.frame.size.width = max(self.frame.width * 0.6, minimumThickness)
                marker.view.frame.size.height = lineNumberCell.textSize.height
                marker.view.frame.origin.x = lineNumberCell.frame.size.width - marker.view.frame.size.width - 1.5 /* separator */
                // Center marker vertically on the line number text
                marker.view.frame.origin.y = lineNumberCell.frame.origin.y + lineNumberCell.textVisualCenter - (marker.view.frame.size.height / 2)
                markerContainerView.addSubview(marker.view)
            }
        }
    }

    override open func mouseDown(with event: NSEvent) {
        defer {
            _isDragging = false
        }

        if areMarkersEnabled {
            let eventPoint = containerView.convert(event.locationInWindow, from: nil)
            let lineNumberCell = containerView.subviews
                .compactMap { $0 as? STGutterLineNumberCell }
                .first { $0.frame.contains(eventPoint) }

            if let lineNumberCell, marker(lineNumber: lineNumberCell.lineNumber) == nil {
                addMarker(STGutterMarker(lineNumber: lineNumberCell.lineNumber))
                _didMouseDownAddMarker = true
                return
            }
        }

        super.mouseDown(with: event)
    }


    override open func mouseUp(with event: NSEvent) {
        defer {
            _didMouseDownAddMarker = false
            _isDragging = false
        }

        if areMarkersEnabled {
            let eventPoint = containerView.convert(event.locationInWindow, from: nil)
            let lineNumberCell = containerView.subviews
                .compactMap { $0 as? STGutterLineNumberCell }
                .first { $0.frame.contains(eventPoint) }

            let tapOnMark = markerContainerView.subviews.contains(where: { $0.frame.contains(markerContainerView.convert(event.locationInWindow, from: nil)) })
            if let lineNumberCell, tapOnMark, !_didMouseDownAddMarker {
                removeMarker(lineNumber: lineNumberCell.lineNumber)
                return
            }
        }

        super.mouseUp(with: event)
    }

    override public func mouseDragged(with event: NSEvent) {
        defer {
            _isDragging = true
        }

        if areMarkersEnabled {
            let eventPoint = containerView.convert(event.locationInWindow, from: nil)
            let lineNumberCell = containerView.subviews
                .compactMap { $0 as? STGutterLineNumberCell }
                .first { $0.frame.contains(eventPoint) }

            let tapOnMark = markerContainerView.subviews.contains(where: { $0.frame.contains(markerContainerView.convert(event.locationInWindow, from: nil)) })
            if !_isDragging, tapOnMark, !_didMouseDownAddMarker, let lineNumberCell, let marker = marker(lineNumber: lineNumberCell.lineNumber) {
                let pasteboardItem = NSPasteboardItem()
                pasteboardItem.setString("", forType: .string)
                let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
                draggingItem.setDraggingFrame(
                    CGRect(origin: marker.view.frame.origin, size: marker.view.frame.size),
                    contents: marker.view.stImage()
                )
                let draggingSession = beginDraggingSession(with: [draggingItem], event: event, source: self)
                draggingSession.animatesToStartingPositionsOnCancelOrFail = false
                _draggingMarker = marker
                return
            }
        }

        super.mouseDragged(with: event)
    }

    // MARK: NSDraggingSource

    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .delete
    }

    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if let _draggingMarker {
            removeMarker(lineNumber: _draggingMarker.lineNumber)
            self._draggingMarker = nil
        }
    }
}

private func adjustGutterFont(_ font: NSFont) -> NSFont {
    // https://useyourloaf.com/blog/ios-9-proportional-numbers/
    // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM09/AppendixF.html
    let features: [[NSFontDescriptor.FeatureKey: Int]] = [
        [
            .typeIdentifier: kTextSpacingType,
            .selectorIdentifier: kMonospacedTextSelector
        ],
        [
            .typeIdentifier: kNumberSpacingType,
            .selectorIdentifier: kMonospacedNumbersSelector
        ],
        [
            .typeIdentifier: kNumberCaseType,
            .selectorIdentifier: kUpperCaseNumbersSelector
        ],
        [
            .typeIdentifier: kStylisticAlternativesType,
            .selectorIdentifier: kStylisticAltOneOnSelector
        ],
        [
            .typeIdentifier: kStylisticAlternativesType,
            .selectorIdentifier: kStylisticAltTwoOnSelector
        ],
        [
            .typeIdentifier: kTypographicExtrasType,
            .selectorIdentifier: kSlashedZeroOnSelector
        ]
    ]

    return NSFont(descriptor: font.fontDescriptor.addingAttributes([.featureSettings: features]), size: 0) ?? font
}

// MARK: - NSViewInvalidating

private extension NSViewInvalidating where Self == STGutterView.Invalidations.Markers {
    static var markers: STGutterView.Invalidations.Markers {
        STGutterView.Invalidations.Markers()
    }

    static var background: STGutterView.Invalidations.Background {
        STGutterView.Invalidations.Background()
    }
}

private extension STGutterView.Invalidations {
    struct Markers: NSViewInvalidating {
        func invalidate(view: NSView) {
            guard let view = view as? STGutterView else {
                return
            }

            view.layoutMarkers()
        }
    }

    struct Background: NSViewInvalidating {
        func invalidate(view: NSView) {
            guard let view = view as? STGutterView else {
                return
            }

            view.updateBackgroundColor()
        }
    }
}
