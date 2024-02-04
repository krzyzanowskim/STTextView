//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

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

    /// A Boolean indicating whether to draw a separator or not.
    @Invalidating(.display)
    open var drawSeparator: Bool = true

    /// The background color of the ruler view.
    @Invalidating(.display)
    open var backgroundColor: NSColor = NSColor.controlBackgroundColor

    @Invalidating(.display)
    open var highlightSelectedLine: Bool = false

    /// A Boolean value that indicates whether the receiver draws its background.
    @Invalidating(.display)
    open var drawsBackground: Bool = true
    
    /// The background color of the highlighted line.
    @Invalidating(.display)
    open var selectedLineHighlightColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)
    
    /// The text color of the highlighted line numbers.
    @Invalidating(.display)
    open var selectedLineTextColor: NSColor? = nil

    /// The color of the separator.
    ///
    /// Needs ``drawSeparator`` to be set to `true`.
    @Invalidating(.display)
    open var separatorColor: NSColor = NSColor.separatorColor

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

    struct Line {
        let number: Int
        let textPosition: CGPoint
        let layoutFragmentFrame: CGRect
        let ctLine: CTLine
        let isSelected: Bool
    }
    
    private var lines: [Line] = []
    
    public required init(textView: STTextView, scrollView: NSScrollView? = nil) {
        super.init(scrollView: scrollView ?? textView.enclosingScrollView, orientation: .verticalRuler)

        if let textViewFont = textView.font {
            font = adjustFont(textViewFont)
        }

        highlightSelectedLine = textView.highlightSelectedLine
        selectedLineHighlightColor = textView.selectedLineHighlightColor
        selectedLineTextColor = textView.textColor

        clientView = textView

        NotificationCenter.default.addObserver(forName: STTextView.didChangeSelectionNotification, object: textView.textLayoutManager, queue: .main) { [weak self] _ in
            self?.invalidateHashMarks()
        }
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func invalidateHashMarks() {
        invalidateLineNumbers()
        needsDisplay = true
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

    private func invalidateLineNumbers() {
        guard let textView,
              let textContentManager = textView.textLayoutManager.textContentManager,
              let viewportRange = textView.textLayoutManager.textViewportLayoutController.viewportRange
        else {
            return
        }

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor.cgColor
        ]
        
        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (selectedLineTextColor ?? textColor).cgColor
        ]

        lines.removeAll(keepingCapacity: true)

        if textView.textLayoutManager.documentRange.isEmpty {
            // For empty document, layout the extra line as if it has text in it
            // the ExtraLineFragment doesn't have information about typing attributes hence layout manager uses a default values - not from text view
            textView.textLayoutManager.enumerateTextLayoutFragments(from: textView.textLayoutManager.documentRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { layoutFragment in
                for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {

                    var baselineOffset: CGFloat = 0
                    if let paragraphStyle = textView.typingAttributes[.paragraphStyle] as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineOffset = -(textView.typingLineHeight * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                    }

                    let lineNumber = lines.count + 1

                    var effectiveAttributes = lineTextAttributes

                    if highlightSelectedLine, !selectedLineTextAttributes.isEmpty {
                        effectiveAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                    }

                    let attributedString = NSAttributedString(string: "\(lineNumber)", attributes: effectiveAttributes)
                    let ctLine = CTLineCreateWithAttributedString(attributedString)

                    let locationForFirstCharacter = CGPoint(x: 0, y: calculateDefaultLineHeight(for: lineTextAttributes[.font] as! NSFont))
                    let lineFragmentFrame = CGRect(origin: CGPoint(x: 0, y: layoutFragment.layoutFragmentFrame.origin.y), size: layoutFragment.layoutFragmentFrame.size)

                    lines.append(
                        Line(
                            number: lineNumber,
                            textPosition: lineFragmentFrame.origin.moved(dy: locationForFirstCharacter.y + baselineOffset),
                            layoutFragmentFrame: CGRect(x: 0, y: lineFragmentFrame.origin.y, width: lineFragmentFrame.width, height: textView.typingLineHeight),
                            ctLine: ctLine,
                            isSelected: true
                        )
                    )
                }

                return false
            }
        } else {
            let textElements = textContentManager.textElements(for: NSTextRange(location: textView.textLayoutManager.documentRange.location, end: viewportRange.location)!)
            let startLineIndex = textElements.count

            textView.textLayoutManager.enumerateTextLayoutFragments(in: viewportRange, options: [.ensuresLayout, .ensuresExtraLineFragment]) { layoutFragment in
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

                for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {
                    var baselineYOffset: CGFloat = 0

                    if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineYOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                    }

                    let lineNumber = startLineIndex + lines.count + 1
                    let locationForFirstCharacter = lineFragment.locationForCharacter(at: 0)

                    var effectiveAttributes = lineTextAttributes

                    let isLineSelected: Bool = {
                        textView.textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
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
                    }()


                    if highlightSelectedLine, !selectedLineTextAttributes.isEmpty, isLineSelected {
                        effectiveAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                    }

                    let attributedString = NSAttributedString(string: "\(lineNumber)", attributes: effectiveAttributes)
                    let ctLine = CTLineCreateWithAttributedString(attributedString)

                    var lineFragmentFrame = CGRect(origin: CGPoint(x: 0, y: layoutFragment.layoutFragmentFrame.origin.y), size: layoutFragment.layoutFragmentFrame.size)

                    lineFragmentFrame.origin.y += lineFragment.typographicBounds.origin.y
                    if lineFragment.isExtraLineFragment {
                        lineFragmentFrame.size.height = lineFragment.typographicBounds.height
                    } else if !lineFragment.isExtraLineFragment, let extraLineFragment = layoutFragment.textLineFragments.first(where: { $0.isExtraLineFragment }) {
                        lineFragmentFrame.size.height -= extraLineFragment.typographicBounds.height
                    }

                    lines.append(
                        Line(
                            number: lineNumber,
                            textPosition: lineFragmentFrame.origin.moved(dy: locationForFirstCharacter.y + baselineYOffset),
                            layoutFragmentFrame: lineFragmentFrame,
                            ctLine: ctLine,
                            isSelected: isLineSelected
                        )
                    )
                }

                return true
            }
        }

        // Adjust ruleThickness based on last (longest) value
        let prevThickness = ruleThickness
        var calculatedThickness: CGFloat = ruleThickness
        if let lastLine = lines.last {
            let ctLineWidth = ceil(CTLineGetTypographicBounds(lastLine.ctLine, nil, nil, nil))
            if calculatedThickness < (ctLineWidth + (rulerInsets.leading + rulerInsets.trailing)) {
                calculatedThickness = max(calculatedThickness, ctLineWidth + (rulerInsets.leading + rulerInsets.trailing))
            }
        }

        let delta = prevThickness - calculatedThickness
        if !delta.isZero {
            self.ruleThickness = calculatedThickness
            if let scrollView = scrollView {
                let clipView = scrollView.contentView
                clipView.bounds.origin.x = -(clipView.contentInsets.left + clipView.contentInsets.right)

                invalidateMarkersRect()
            }
        }

        // align to right
        lines = lines.map {
            let ctLineWidth = ceil(CTLineGetTypographicBounds($0.ctLine, nil, nil, nil))

            return Line(
                number: $0.number,
                textPosition: $0.textPosition.moved(dx: requiredThickness - (ctLineWidth + rulerInsets.trailing), dy: -baselineOffset),
                layoutFragmentFrame: $0.layoutFragmentFrame,
                ctLine: $0.ctLine,
                isSelected: $0.isSelected
            )
        }

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

    private func drawHighlightedRuler(line: Line, at relativePoint: NSPoint, in dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.setFillColor(selectedLineHighlightColor.cgColor)

        let fillRect = CGRect(
            origin: CGPoint(x: 0, y: line.layoutFragmentFrame.origin.y + relativePoint.y),
            size: CGSize(
                width: bounds.width,
                height: line.layoutFragmentFrame.height
            )
        ).pixelAligned
        context.fill(fillRect)
        context.restoreGState()
    }

    open override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext, let textView = textView else { return }

        drawBackground(in: dirtyRect)
        drawHashMarksAndLabels(in: dirtyRect)

        if markers?.isEmpty == false {
            drawMarkers(in: dirtyRect)
        }

        let relativePoint = self.convert(NSZeroPoint, from: textView)
        context.saveGState()

        if drawSeparator {
            context.setLineWidth(1)
            context.setStrokeColor(separatorColor.cgColor)
            context.addLines(between: [CGPoint(x: requiredThickness - 0.5, y: 0), CGPoint(x: requiredThickness - 0.5, y: bounds.maxY) ])
            context.strokePath()
        }
        
        context.textMatrix = CGAffineTransform(scaleX: 1, y: isFlipped ? -1 : 1)

        for line in lines where dirtyRect.inset(dy: -font.pointSize).contains(line.textPosition.moved(dy: relativePoint.y)) {

            // Draw a background rectangle to highlight the selected ruler line
            if highlightSelectedLine, line.isSelected, textView.textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty {
                drawHighlightedRuler(line: line, at: relativePoint, in: dirtyRect)
            }

            context.textPosition = line.textPosition.moved(dy: relativePoint.y)
            CTLineDraw(line.ctLine, context)
        }

        context.restoreGState()
    }
    
}

private extension STLineNumberRulerView {
    func adjustFont(_ font: NSFont) -> NSFont {
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
}
