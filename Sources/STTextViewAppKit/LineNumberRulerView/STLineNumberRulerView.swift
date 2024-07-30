//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus
import STTextViewCommon

/// A ruler view to display line numbers to the side of the text view.
open class STLineNumberRulerView: NSRulerView {

    private var textView: STTextView? {
        clientView as? STTextView
    }

    /// The font used to draw line numbers.
    ///
    /// Initialized with a textView font value and does not update automatically when
    /// text view font changes.
    @Invalidating(.display)
    open var font: NSFont = NSFont(descriptor: NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular).fontDescriptor.withSymbolicTraits(.condensed), size: 0) ?? NSFont.monospacedSystemFont(ofSize: 0, weight: .regular)

    /// The insets of the ruler view.
    @Invalidating(.display)
    open var rulerInsets: STRulerInsets = STRulerInsets(leading: 6.0, trailing: 6.0)
    
    /// The text color of the line numbers.
    @Invalidating(.display)
    open var textColor: NSColor = .secondaryLabelColor

    /// A Boolean indicating whether to draw a separator or not. Default true.
    @Invalidating(.display)
    open var drawSeparator: Bool = true

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    @Invalidating(.display)
    open var separatorColor: NSColor = NSColor.separatorColor

    /// The background color of the ruler view.
    @Invalidating(.display)
    open var backgroundColor: NSColor = NSColor.controlBackgroundColor

    /// A Boolean that controls whether the text view highlights the currently selected line. Default false.
    @Invalidating(.display)
    open var highlightSelectedLine: Bool = false

    /// A Boolean value that indicates whether the receiver draws its background. Default true.
    @Invalidating(.display)
    open var drawsBackground: Bool = true
    
    /// The background color of the highlighted line.
    @Invalidating(.display)
    open var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)
    
    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    open var selectedLineTextColor: NSColor? = nil

    /// The bottom baseline offset of each line number.
    ///
    /// Use this to offset the line number when the line height is not the default of the used font.
    @Invalidating(.display)
    open var baselineOffset: CGFloat = 0

    /// Allows to set markers. Disabled by default.
    @Invalidating(.layout)
    open var allowsMarkers: Bool = false

    public override var reservedThicknessForMarkers: CGFloat {
        get {
            // Never called anyway
            super.reservedThicknessForMarkers
        }

        set {
            // Sadly something from addMarker adds 2px and there's no easy way to fix it
            // super.reservedThicknessForMarkers = newValue
        }
    }

    private let lineNumberViewContainer: STLineNumberViewContainer

    public required init(textView: STTextView, scrollView: NSScrollView? = nil) {
        lineNumberViewContainer = STLineNumberViewContainer()

        super.init(scrollView: scrollView ?? textView.enclosingScrollView, orientation: .verticalRuler)

        if let textViewFont = textView.font {
            font = adjustFont(textViewFont)
        }

        highlightSelectedLine = textView.highlightSelectedLine
        selectedLineHighlightColor = textView.selectedLineHighlightColor
        selectedLineTextColor = textView.textColor

        clientView = textView

        NotificationCenter.default.addObserver(forName: STTextView.didChangeSelectionNotification, object: textView, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.needsLayout = true
        }

        if let clipView = self.scrollView?.contentView {
            NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: clipView, queue: .main) { [weak self] notification in
                guard let self = self else { return }
                self.needsLayout = true
            }
        }

        addSubview(lineNumberViewContainer)
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var isFlipped: Bool {
        true
    }

    open override func invalidateHashMarks() {
        needsDisplay = true
        needsLayout = true
    }

    open override func layout() {
        super.layout()
        lineNumberViewContainer.frame = frame
        layoutLineNumbers()
    }

    private func layoutLineNumbers() {
        guard let textView = clientView as? STTextView,
              let textContentManager = textView.textLayoutManager.textViewportLayoutController.textLayoutManager?.textContentManager,
              let textLayoutManager = textView.textLayoutManager.textViewportLayoutController.textLayoutManager,
              let viewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange
        else {
            return
        }

        let rulerView = self
        let relativePoint = self.convert(NSZeroPoint, from: textView)

        rulerView.lineNumberViewContainer.subviews.forEach { v in
            v.removeFromSuperviewWithoutNeedingDisplay()
        }

        let textElements = textContentManager.textElements(
            for: NSTextRange(
                location: textLayoutManager.documentRange.location,
                end: viewportRange.location
            )!
        )

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor.cgColor
        ]

        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (selectedLineTextColor ?? textColor).cgColor
        ]

        let startLineIndex = textElements.count
        var linesCount = 0

        // For empty document, layout the extra line as if it has text in it
        // the ExtraLineFragment doesn't have information about typing attributes hence layout manager uses a default values - not from text view
        textLayoutManager.enumerateTextLayoutFragments(in: viewportRange, options: .ensuresExtraLineFragment) { layoutFragment in
            let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

            for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {

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

                let isLineSelected = isLineSelected()

                // vertical line height offset
                var baselineYOffset: CGFloat = 0

                if lineFragment.isExtraLineFragment {
                    if let paragraphStyle = textView.typingAttributes[.paragraphStyle] as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineYOffset = -(textView.typingLineHeight * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                    }
                } else {
                    if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineYOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                    }
                }

                let lineNumber = startLineIndex + linesCount + 1
                var glyphOriginY = lineFragment.glyphOrigin.y
                if lineFragment.isExtraLineFragment {
                    // fake origin for space
                    // there must be better way to calculate glyphOrigin value that matches textView layoutManager
                    // but I didn't find it yet.
                    // Setup temporary layout for a space character and get the glyph origin for typing attributes
                    let layoutManager = NSTextLayoutManager()
                    layoutManager.textContainer = NSTextContainer()
                    layoutManager.textContainer?.lineFragmentPadding = textView.textContainer.lineFragmentPadding
                    let contentManager = NSTextContentStorage()
                    contentManager.addTextLayoutManager(layoutManager)
                    contentManager.attributedString = NSAttributedString(string: "W", attributes: textView.typingAttributes)
                    layoutManager.enumerateTextLayoutFragments(from: nil, options: .ensuresLayout) { frag in
                        glyphOriginY = frag.textLineFragments.first?.glyphOrigin.y ?? 0
                        return false
                    }
                }

                var lineFragmentFrame = CGRect(
                    x: 0,
                    y: layoutFragment.layoutFragmentFrame.origin.y + lineFragment.typographicBounds.origin.y,
                    width: layoutFragment.layoutFragmentFrame.size.width,
                    height: layoutFragment.layoutFragmentFrame.size.height
                )

                if lineFragment.isExtraLineFragment {
                    lineFragmentFrame.size.height = max(textView.typingLineHeight, lineFragment.typographicBounds.height)
                } else if !lineFragment.isExtraLineFragment, let extraLineFragment = layoutFragment.textLineFragments.first(where: { $0.isExtraLineFragment }) {
                    lineFragmentFrame.size.height -= extraLineFragment.typographicBounds.height
                }

                var effectiveLineTextAttributes = lineTextAttributes
                if highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                    effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                }

                let numberView = STLineNumberView(
                    firstBaseline: glyphOriginY + baselineYOffset,
                    attributes: effectiveLineTextAttributes,
                    number: lineNumber
                )

                numberView.insets = rulerInsets

                if highlightSelectedLine, isLineSelected, textView.textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty, !textView.textLayoutManager.insertionPointSelections.isEmpty {
                    numberView.layer?.backgroundColor = selectedLineHighlightColor.cgColor
                } else {
                    numberView.layer?.backgroundColor = nil
                }

                numberView.frame = CGRect(
                    origin: lineFragmentFrame.origin.moved(dy: relativePoint.y),
                    size: CGSize(
                        width: max(lineFragmentFrame.intersection(rulerView.lineNumberViewContainer.frame).width, rulerView.lineNumberViewContainer.frame.width),
                        height: lineFragmentFrame.size.height
                    )
                ).pixelAligned

                rulerView.lineNumberViewContainer.addSubview(numberView)
                linesCount += 1
            }

            return true
        }

        // adjust ruleThickness to fit the text based on last numberView
        if let lastNumberView = lineNumberViewContainer.subviews.last as? STLineNumberView {
            let prevThickness = self.ruleThickness
            let calculatedThickness = max(self.requiredThickness, lastNumberView.intrinsicContentSize.width + 8)
            let delta = prevThickness - calculatedThickness
            if !delta.isAlmostZero() {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                // the internal call to NSScrollView.tile() result
                // in a glitch with the offset
                self.ruleThickness = calculatedThickness
                CATransaction.commit()
            }
        }
    }

    open override func addMarker(_ marker: NSRulerMarker) {
        guard allowsMarkers else {
            return
        }

        guard clientView != nil else {
            assertionFailure("receiver has no client view")
            return
        }

        if markers == nil {
            markers = [marker]
        } else {
            markers?.append(marker)
        }
        enclosingScrollView?.tile()
    }

    private func invalidateMarkersRect() {
        guard let markers = markers, !markers.isEmpty else {
            return
        }

        for marker in markers {
            (marker as? STRulerMarker)?.size.width = ruleThickness
        }
    }

    open override func drawHashMarksAndLabels(in rect: NSRect) {
        //
    }
    

    open func drawBackground(in dirtyRect: NSRect) {
        guard drawsBackground, let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.setFillColor(backgroundColor.cgColor)
        context.fill(bounds)
        context.restoreGState()
    }

    open override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        drawBackground(in: dirtyRect)
        drawHashMarksAndLabels(in: dirtyRect)

        if markers?.isEmpty == false {
            drawMarkers(in: dirtyRect)
        }

        context.saveGState()

        if drawSeparator {
            context.setLineWidth(1)
            context.setStrokeColor(separatorColor.cgColor)
            context.addLines(between: [CGPoint(x: requiredThickness - 0.5, y: dirtyRect.minY), CGPoint(x: requiredThickness - 0.5, y: dirtyRect.maxY) ])
            context.strokePath()
        }

        context.restoreGState()
    }
    
}

private func adjustFont(_ font: NSFont) -> NSFont {
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

    let adjustedFont = NSFont(descriptor: font.fontDescriptor.addingAttributes([.featureSettings: features]), size: 0)
    return adjustedFont ?? font
}
