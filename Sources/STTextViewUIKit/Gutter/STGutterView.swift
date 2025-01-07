//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

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

/// A gutter to the side of a scroll view’s document view.
open class STGutterView: UIView {
    internal let containerView: UIView
    internal let markerContainerView: UIView

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
    open var insets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)

    /// Minimum thickness.
    @Invalidating(.layout)
    open var minimumThickness: CGFloat = 40

    /// The text color of the line numbers.
    @Invalidating(.display)
    open var textColor = UIColor.secondaryLabel

    /// A Boolean indicating whether to draw a separator or not. Default true.
    @Invalidating(.display)
    open var drawSeparator: Bool = true

    /// A Boolean that controls whether the text view highlights the currently selected line. Default false.
    @Invalidating(.display)
    open var highlightSelectedLine: Bool = false

    /// The background color of the highlighted line.
    @Invalidating(.display)
    open var selectedLineHighlightColor: UIColor = .tintColor.withAlphaComponent(0.15)

    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    open var selectedLineTextColor: UIColor? = nil

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    @Invalidating(.display)
    open var separatorColor = UIColor.separator.withAlphaComponent(0.1)

    /// The receiver’s gutter markers to markers, removing any existing ruler markers and not consulting with the client view about the new markers.
    @Invalidating(.markers)
    private(set) var markers: [STGutterMarker] = []

    /// A Boolean value that determines whether the markers functionality is in an enabled state. Default `false.`
    open var areMarkersEnabled: Bool = false {
        didSet {
            tapGestureRecognizer?.isEnabled = areMarkersEnabled
        }
    }
    private var tapGestureRecognizer: UIGestureRecognizer?

    public override init(frame: CGRect) {
        containerView = UIView(frame: frame)
        containerView.clipsToBounds = true
        containerView.isOpaque = true
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        markerContainerView = UIView(frame: frame)
        markerContainerView.clipsToBounds = true
        markerContainerView.isOpaque = true
        markerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        super.init(frame: frame)
        isUserInteractionEnabled = true
        isOpaque = false

        addSubview(containerView)
        addSubview(markerContainerView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)
        self.tapGestureRecognizer = tapGestureRecognizer
        tapGestureRecognizer.isEnabled = areMarkersEnabled
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundColor = self.backgroundColor?.resolvedColor(with: traitCollection) ?? UIColor.systemBackground.resolvedColor(with: traitCollection)
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        if drawSeparator {
            context.setLineWidth(1)
            context.setStrokeColor(separatorColor.cgColor)
            context.addLines(between: [CGPoint(x: frame.width - 0.5, y: 0), CGPoint(x: frame.width - 0.5, y: bounds.maxY) ])
            context.strokePath()
        }
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

    internal func layoutMarkers() {
        for v in markerContainerView.subviews {
            v.removeFromSuperview()
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
                markerContainerView.addSubview(marker.view)
                marker.view.frame.size = cellView.frame.size
                marker.view.frame.origin = cellView.frame.origin
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
