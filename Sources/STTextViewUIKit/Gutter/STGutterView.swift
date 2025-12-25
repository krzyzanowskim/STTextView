//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//  STGutterView
//      |- UIVisualEffectView
//      |- STGutterContainerView
//      |- STGutterSeparatorView
//          |-STGutterLineNumberCell
//      |- STGutterMarkerContainerView
//          |-STGutterMarker.view

import UIKit
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

/// A gutter to the side of a scroll view's document view.
open class STGutterView: UIView {
    let separatorView: STGutterSeparatorView
    let containerView: STGutterContainerView
    let markerContainerView: STGutterMarkerContainerView

    /// Delegate
    weak var delegate: (any STGutterViewDelegate)?

    /// The font used to draw line numbers.
    ///
    /// Initialized with a textView font value and does not update automatically when
    /// text view font changes.
    @Invalidating(.display)
    open var font = adjustGutterFont(UIFont(descriptor: UIFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.traitCondensed)!, size: 0))

    /// The insets of the ruler view.
    @Invalidating(.display)
    open var insets = STRulerInsets(leading: 4.0, trailing: 6.0)

    /// Minimum thickness.
    @Invalidating(.layout)
    open var minimumThickness: CGFloat = 35

    /// The text color of the line numbers.
    @Invalidating(.display)
    open var textColor = UIColor.secondaryLabel

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
    open var highlightSelectedLine = false

    /// The background color of the highlighted line.
    @Invalidating(.display)
    open var selectedLineHighlightColor: UIColor = .tintColor.withAlphaComponent(0.15)

    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    open var selectedLineTextColor: UIColor? = nil

    open override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor == nil, _backgroundEffectView == nil {
                let backgroundEffect = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                backgroundEffect.frame = bounds
                backgroundEffect.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                // insert subview to `self`. below other subviews.
                self.insertSubview(backgroundEffect, at: 0)
                self._backgroundEffectView = backgroundEffect
            } else if backgroundColor != nil, _backgroundEffectView != nil {
                _backgroundEffectView?.removeFromSuperview()
                _backgroundEffectView = nil
            }
        }
    }

    private var _backgroundEffectView: UIVisualEffectView?

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    open var separatorColor: UIColor {
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
    open var areMarkersEnabled = false {
        didSet {
            tapGestureRecognizer?.isEnabled = areMarkersEnabled
        }
    }

    private var tapGestureRecognizer: UIGestureRecognizer?

    override public init(frame: CGRect) {
        separatorView = STGutterSeparatorView(frame: frame)
        separatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        containerView = STGutterContainerView(frame: frame)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        markerContainerView = STGutterMarkerContainerView(frame: frame)
        markerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = true
        isOpaque = false

        // Add marker container first so it's behind line numbers
        addSubview(markerContainerView)
        addSubview(containerView)
        addSubview(separatorView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)
        self.tapGestureRecognizer = tapGestureRecognizer
        tapGestureRecognizer.isEnabled = areMarkersEnabled

        updateBackgroundColor()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateBackgroundColor()
        }
    }

    fileprivate func updateBackgroundColor() {
        self.backgroundColor = backgroundColor
    }

    @objc private func handleTapGesture(_ sender: UIGestureRecognizer) {
        let eventPoint = sender.location(in: containerView)
        let cellView = containerView.subviews
            .compactMap {
                $0 as? STGutterLineNumberCell
            }
            .first {
                $0.frame.contains(eventPoint)
            }

        if let cellView {
            if marker(lineNumber: cellView.lineNumber) != nil {
                removeMarker(lineNumber: cellView.lineNumber)
                return
            } else if delegate?.textViewGutterShouldAddMarker(self) ?? true {
                addMarker(STGutterMarker(lineNumber: cellView.lineNumber))
                return
            }
        }
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
            v.removeFromSuperview()
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
}

private func adjustGutterFont(_ font: UIFont) -> UIFont {
    // https://useyourloaf.com/blog/ios-9-proportional-numbers/
    // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM09/AppendixF.html
    let features: [[UIFontDescriptor.FeatureKey: Int]] = [
        [
            .type: kTextSpacingType,
            .selector: kMonospacedTextSelector
        ],
        [
            .type: kNumberSpacingType,
            .selector: kMonospacedNumbersSelector
        ],
        [
            .type: kNumberCaseType,
            .selector: kUpperCaseNumbersSelector
        ],
        [
            .type: kStylisticAlternativesType,
            .selector: kStylisticAltOneOnSelector
        ],
        [
            .type: kStylisticAlternativesType,
            .selector: kStylisticAltTwoOnSelector
        ],
        [
            .type: kTypographicExtrasType,
            .selector: kSlashedZeroOnSelector
        ]
    ]

    return UIFont(descriptor: font.fontDescriptor.addingAttributes([.featureSettings: features]), size: 0)
}

// MARK: - UIViewInvalidating

private extension UIViewInvalidating where Self == STGutterView.Invalidations.Markers {
    static var markers: STGutterView.Invalidations.Markers {
        STGutterView.Invalidations.Markers()
    }
}

private extension STGutterView.Invalidations {
    struct Markers: UIViewInvalidating {
        func invalidate(view: UIView) {
            guard let view = view as? STGutterView else {
                return
            }

            view.layoutMarkers()
        }
    }
}
