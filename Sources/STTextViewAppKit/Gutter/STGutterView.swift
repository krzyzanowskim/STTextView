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
    internal let separatorView: STGutterSeparatorView
    internal let containerView: STGutterContainerView
    internal let markerContainerView: STGutterMarkerContainerView

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
    open var insets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)

    /// Minimum thickness.
    @Invalidating(.layout)
    open var minimumThickness: CGFloat = 40

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
    @Invalidating(.display)
    open var highlightSelectedLine: Bool = false

    @Invalidating(.display, .background)
    internal var backgroundColor: NSColor? = nil {
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
    open var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)

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
    open var areMarkersEnabled: Bool = false

    public override var isOpaque: Bool {
        false
    }

    open override var isFlipped: Bool {
        true
    }

    open override var allowsVibrancy: Bool {
        true
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

        addSubview(separatorView)
        addSubview(containerView)
        addSubview(markerContainerView)

        updateBackgroundColor()
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            updateBackgroundColor()
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

    internal func layoutMarkers() {
        for v in markerContainerView.subviews {
            v.removeFromSuperviewWithoutNeedingDisplay()
        }

        for marker in markers {
            let cellView = containerView.subviews
                .compactMap {
                    $0 as? STGutterLineNumberCell
                }
                .first {
                    $0.lineNumber == marker.lineNumber
                }

            if let cellView {
                marker.view.frame.origin = cellView.frame.origin
                marker.view.frame.size = cellView.frame.size
                marker.view.frame.size.height = min(cellView.textSize.height + cellView.firstBaselineOffsetFromTop, cellView.frame.size.height)
                markerContainerView.addSubview(marker.view)
            }
        }
    }

    open override func mouseDown(with event: NSEvent) {
        if areMarkersEnabled, event.type == .leftMouseDown, event.clickCount == 1 {
            let eventPoint = containerView.convert(event.locationInWindow, from: nil)
            let cellView = containerView.subviews
                .compactMap {
                    $0 as? STGutterLineNumberCell
                }
                .first {
                    $0.frame.contains(eventPoint)
                }

            if let cellView {
                if let marker = marker(lineNumber: cellView.lineNumber) {
                    let pasteboardItem = NSPasteboardItem()
                    pasteboardItem.setString("", forType: .string)
                    let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
                    draggingItem.setDraggingFrame(CGRect(origin: cellView.frame.origin, size: marker.view.frame.size), contents: marker.view.stImage())
                    let draggingSession = beginDraggingSession(with: [draggingItem], event: event, source: self)
                    draggingSession.animatesToStartingPositionsOnCancelOrFail = false
                    draggingMarker = marker
                } else if delegate?.textViewGutterShouldAddMarker(self) ?? true {
                    addMarker(STGutterMarker(lineNumber: cellView.lineNumber))
                }
                return
            }
        }

        super.mouseDown(with: event)
    }

    private var draggingMarker: STGutterMarker?

    public override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
    }

    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .delete
    }

    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if let draggingMarker {
            removeMarker(lineNumber: draggingMarker.lineNumber)
            self.draggingMarker = nil
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
