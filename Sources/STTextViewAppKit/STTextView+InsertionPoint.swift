//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit
import STTextKitPlus

extension STTextView {

    /// Updates the insertion point's location and optionally restarts the blinking cursor timer.
    public func updateInsertionPointStateAndRestartTimer() {
        // Hide insertion point layers
        if shouldDrawInsertionPoint {
            let insertionPointSelections = textLayoutManager.insertionPointSelections
            let insertionPointsRanges = insertionPointSelections.flatMap(\.textRanges).filter(\.isEmpty)
            guard !insertionPointsRanges.isEmpty else {
                return
            }

            // Check if any selection has upstream affinity (for proper end-of-wrapped-line positioning)
            let hasUpstreamAffinity = insertionPointSelections.contains { $0.affinity == .upstream }
            let segmentOptions: NSTextLayoutManager.SegmentOptions = hasUpstreamAffinity ? .upstreamAffinity : []

            // rewrite it to lines
            var textSelectionFrames: [CGRect] = []
            for selectionTextRange in insertionPointsRanges {
                textLayoutManager.enumerateTextSegments(in: selectionTextRange, type: .standard, options: segmentOptions) { textSegmentRange, textSegmentFrame, _, _ in
                    if let textSegmentRange {
                        let documentRange = textLayoutManager.documentRange
                        guard !documentRange.isEmpty else {
                            // empty document
                            textSelectionFrames.append(
                                CGRect(
                                    origin: CGPoint(
                                        x: textSegmentFrame.origin.x,
                                        y: textSegmentFrame.origin.y
                                    ),
                                    size: CGSize(
                                        width: textSegmentFrame.width,
                                        height: typingLineHeight
                                    )
                                )
                            )
                            return false
                        }

                        let isAtEndLocation = textSegmentRange.location == documentRange.endLocation
                        guard !isAtEndLocation else {
                            // At the end of non-empty document

                            // FB15131180: extra line fragment frame is not correct hence workaround location and height at extra line
                            if let layoutFragment = textLayoutManager.extraLineTextLayoutFragment() {
                                // at least 2 lines guaranteed at this point
                                let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                                let extraLineFragment = layoutFragment.textLineFragments.last!

                                // Get paragraph style from previous line for consistent line height.
                                // Note: Extra line fragments don't need yOffset adjustment because their
                                // Y position is calculated from the layout fragment frame, not textSegmentFrame.
                                let scaledHeight = prevTextLineFragment.stEffectiveLineHeight

                                // Use extra line fragment's own Y position (already includes lineSpacing + paragraphSpacing)
                                textSelectionFrames.append(
                                    CGRect(
                                        origin: CGPoint(
                                            x: textSegmentFrame.origin.x,
                                            y: layoutFragment.layoutFragmentFrame.origin.y + extraLineFragment.typographicBounds.origin.y
                                        ),
                                        size: CGSize(
                                            width: textSegmentFrame.width,
                                            height: scaledHeight
                                        )
                                    )
                                )
                            } else if let prevLocation = textLayoutManager.location(textSegmentRange.endLocation, offsetBy: -1),
                                      let prevTextLineFragment = textLayoutManager.textLineFragment(at: prevLocation) {
                                // Get insertion point height from the last-to-end (last) line fragment location
                                // since we're at the end location at this point.
                                let scaledHeight = prevTextLineFragment.stEffectiveLineHeight

                                textSelectionFrames.append(
                                    CGRect(
                                        origin: CGPoint(
                                            x: textSegmentFrame.origin.x,
                                            y: textSegmentFrame.origin.y
                                        ),
                                        size: CGSize(
                                            width: textSegmentFrame.width,
                                            height: scaledHeight
                                        )
                                    )
                                )
                            }
                            return false
                        }

                        // Regular content line - use paragraph style's effective line height for consistent sizing
                        if let textLineFragment = textLayoutManager.textLineFragment(at: textSegmentRange.location) {
                            let metrics = textLineFragment.stEffectiveLineMetrics

                            textSelectionFrames.append(
                                CGRect(
                                    origin: CGPoint(
                                        x: textSegmentFrame.origin.x,
                                        y: textSegmentFrame.origin.y + metrics.yOffset
                                    ),
                                    size: CGSize(
                                        width: textSegmentFrame.width,
                                        height: metrics.height
                                    )
                                )
                            )
                        } else {
                            // Fallback to segment frame if line fragment not available
                            textSelectionFrames.append(textSegmentFrame)
                        }
                    }
                    return true
                }
            }

            var existingViews = contentView.subviews.filter { view in
                type(of: view) == STInsertionPointView.self
            }

            for selectionFrame in textSelectionFrames where !selectionFrame.isNull && !selectionFrame.isInfinite {
                let insertionViewFrame = CGRect(origin: selectionFrame.origin, size: CGSize(width: max(2, selectionFrame.width), height: selectionFrame.height)).pixelAligned
                let insertionView: STInsertionPointView
                // re-use existing insertion views
                if !existingViews.isEmpty {
                    // reuse existing insertion view
                    insertionView = existingViews.removeFirst() as! STInsertionPointView
                    insertionView.frame = insertionViewFrame
                } else {
                    // add new views that exedes existing views
                    let textInsertionIndicator: any STInsertionPointIndicatorProtocol = if let customTextInsertionIndicator = self.delegateProxy.textViewInsertionPointView(self, frame: CGRect(origin: .zero, size: insertionViewFrame.size)) {
                        customTextInsertionIndicator
                    } else {
                        if #available(macOS 14, *) {
                            STTextInsertionIndicatorNew(frame: CGRect(origin: .zero, size: insertionViewFrame.size))
                        } else {
                            STTextInsertionIndicatorOld(frame: CGRect(origin: .zero, size: insertionViewFrame.size))
                        }
                    }

                    insertionView = STInsertionPointView(frame: insertionViewFrame, textInsertionIndicator: textInsertionIndicator)
                    insertionView.clipsToBounds = false
                    insertionView.insertionPointColor = insertionPointColor
                    contentView.addSubview(insertionView)
                }

                if isFirstResponder {
                    insertionView.blinkStart()
                } else {
                    insertionView.blinkStop()
                }
            }

            // remove unused insertion points (unused)
            for v in existingViews {
                v.removeFromSuperview()
            }
            existingViews.removeAll()

        } else if !shouldDrawInsertionPoint {
            removeInsertionPointView()
        }
    }

    func removeInsertionPointView() {
        contentView.subviews.removeAll { view in
            type(of: view) == STInsertionPointView.self
        }
    }

}

// Adopting the system text cursor in custom text views
// https://developer.apple.com/documentation/appkit/text_display/adopting_the_system_text_cursor_in_custom_text_views
@available(macOS 14.0, *)
private class STTextInsertionIndicatorNew: NSTextInsertionIndicator, STInsertionPointIndicatorProtocol {
    // NSTextInsertionIndicator start as visible (blinking)
    private var _isVisible = true

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        autoresizingMask = [.width, .height]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var insertionPointColor: NSColor {
        get {
            color
        }

        set {
            color = newValue
        }
    }

    func blinkStart() {
        if !_isVisible {
            _isVisible = true
            displayMode = .automatic
        }
    }

    func blinkStop() {
        if _isVisible {
            _isVisible = false
            displayMode = .hidden
        }
    }

    override open var isFlipped: Bool {
        true
    }
}

private class STTextInsertionIndicatorOld: NSView, STInsertionPointIndicatorProtocol {
    private var timer: Timer?

    var insertionPointColor: NSColor = .defaultTextInsertionPoint.withAlphaComponent(0.9) {
        didSet {
            layer?.backgroundColor = insertionPointColor.cgColor
        }
    }

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = insertionPointColor.cgColor
        layer?.cornerRadius = 1
        autoresizingMask = [.width, .height]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func blinkStart() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.isHidden.toggle()
        }
    }

    func blinkStop() {
        isHidden = false
        timer?.invalidate()
        timer = nil
    }

    override open var isFlipped: Bool {
        true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            self.insertionPointColor = self.insertionPointColor
        }
    }
}

