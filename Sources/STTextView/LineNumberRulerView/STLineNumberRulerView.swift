//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

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
    open var font: NSFont = NSFont(descriptor: NSFont.monospacedDigitSystemFont(ofSize: NSFont.labelFontSize, weight: .regular).fontDescriptor.withSymbolicTraits(.condensed), size: NSFont.labelFontSize) ?? NSFont.monospacedSystemFont(ofSize: NSFont.labelFontSize, weight: .regular)

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
    
    /// The text color of the highligted line numbers.
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

    /// Allows to set markers. Enabled by default.
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
        let textPosition: CGPoint
        let textRange: NSTextRange
        let ctLine: CTLine
    }
    
    private var lines: [Line] = []
    
    public required init(textView: STTextView, scrollView: NSScrollView? = nil) {
        super.init(scrollView: scrollView ?? textView.enclosingScrollView, orientation: .verticalRuler)

        if let textViewFont = textView.font {
            font = textViewFont
        }

        highlightSelectedLine = textView.highlightSelectedLine
        selectedLineHighlightColor = textView.selectedLineHighlightColor
        selectedLineTextColor = textView.textColor

        clientView = textView

        NotificationCenter.default.addObserver(forName: STTextView.didChangeSelectionNotification, object: textView.textLayoutManager, queue: .main) { [weak self] _ in
            self?.invalidateLineNumbers()
            self?.needsDisplay = true
        }
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func invalidateHashMarks() {
        invalidateLineNumbers()
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
        guard let textLayoutManager = textView?.textLayoutManager,
              let textContentManager = textLayoutManager.textContentManager,
              let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange
        else {
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: (selectedLineTextColor ?? textColor).cgColor
        ]

        lines.removeAll(keepingCapacity: true)

        if textLayoutManager.documentRange.isEmpty {
            // For empty document, layout the extra line as if it has text in it
            // the ExtraLineFragment doesn't have information about typing attributes hence layout manager uses a default values - not from text view
            textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { layoutFragment in
                for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {

                    var baselineOffset: CGFloat = 0
                    if let paragraphStyle = textView?.defaultParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineOffset = -(textView!.typingLineHeight * (textView!.defaultParagraphStyle!.lineHeightMultiple - 1.0) / 2)
                    }

                    let attributedString = NSAttributedString(string: "\(lines.count + 1)", attributes: attributes)
                    let ctLine = CTLineCreateWithAttributedString(attributedString)

                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    var leading: CGFloat = 0
                    CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
                    let locationForFirstCharacter = CGPoint(x: 0, y: ascent + descent + leading)

                    lines.append(
                        Line(
                            textPosition: layoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y + baselineOffset),
                            textRange: layoutFragment.rangeInElement,
                            ctLine: ctLine
                        )
                    )
                }

                return false
            }
        } else {
            let textElements = textContentManager.textElements(for: NSTextRange(location: textLayoutManager.documentRange.location, end: viewportRange.location)!)
            let startLineIndex = textElements.count
            let firstFragmentLayout = textLayoutManager.textLayoutFragment(for: viewportRange.location)!

            textLayoutManager.enumerateTextLayoutFragments(from: firstFragmentLayout.rangeInElement.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { layoutFragment in

                for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {
                    var baselineOffset: CGFloat = 0

                    if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                    }

                    let locationForFirstCharacter = lineFragment.locationForCharacter(at: 0)
                    let originPoint = layoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y + baselineOffset)
                    let attributedString = NSAttributedString(string: "\(startLineIndex + lines.count + 1)", attributes: determineLineNumberAttribute(originPoint.y, attributes, selectedAttributes: selectedAttributes))
                    let ctLine = CTLineCreateWithAttributedString(attributedString)

                    lines.append(
                        Line(
                            textPosition: layoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y + baselineOffset),
                            textRange: layoutFragment.rangeInElement,
                            ctLine: ctLine
                        )
                    )
                }

                return layoutFragment.rangeInElement.location <= viewportRange.endLocation
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
                scrollView.contentView.bounds.origin.x = -clipView.contentInsets.left
                scrollView.reflectScrolledClipView(clipView)
            }
        }

        // align to right
        lines = lines.map {
            let ctLineWidth = ceil(CTLineGetTypographicBounds($0.ctLine, nil, nil, nil))

            return Line(
                textPosition: $0.textPosition.moved(dx: requiredThickness - (ctLineWidth + rulerInsets.trailing), dy: -baselineOffset),
                textRange: $0.textRange,
                ctLine: $0.ctLine
            )
        }

    }
    
    // Return text attributes depending on whether the ruleline is highlighted or not.
    private func determineLineNumberAttribute(_ yPosition: CGFloat, _ attributes: [NSAttributedString.Key: Any],
                                              selectedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let textLayoutManager = textView?.textLayoutManager,
              let caretLocation = textLayoutManager.insertionPointLocation,
              highlightSelectedLine == true
        else {
            return attributes
        }

        var attr = attributes
        // Get the current highlight frame of the textContainer
        textLayoutManager.enumerateTextSegments(in: NSTextRange(location: caretLocation), type: .highlight, options: [.rangeNotRequired]) { _, textSegmentFrame, _, _ -> Bool in
            // If the y-coordinate of the Ctline is in between the top and bottom edge of the highlight frame, then that ruler line has to be highlighted.
            if textSegmentFrame.origin.y < yPosition && ((textSegmentFrame.origin.y + textSegmentFrame.height) > yPosition) {
                attr = selectedAttributes
                return false
            }
            return true
        }
        return attr
    }

    open override func drawHashMarksAndLabels(in rect: NSRect) {
        //
    }
    
    // Draw a background rectangle to highlight the selected ruler line
    open func drawHighlightedRuler(_ context: CGContext, _ relativePoint: NSPoint,  in rect: NSRect) {
        guard let textLayoutManager = textView?.textLayoutManager,
              let caretLocation = textLayoutManager.insertionPointLocation,
              let textView = textView
        else {
            return
        }

        textLayoutManager.enumerateTextSegments(in: NSTextRange(location: caretLocation), type: .highlight) { segmentRange, textSegmentFrame, _, _ -> Bool in
            var selectionFrame: NSRect = textSegmentFrame
            
            if segmentRange == textView.textLayoutManager.documentRange {
                selectionFrame = NSRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: textView.typingLineHeight)).pixelAligned
            }
                
            context.saveGState()
            context.setFillColor(selectedLineHighlightColor.cgColor)
                
            let originPoint = CGPoint(x: frame.minX, y: selectionFrame.origin.y).moved(dx: 0, dy: relativePoint.y)

            // Create background rectangle for highlight
            let fillRect = CGRect(
                origin: originPoint,
                size: CGSize(width: frame.width,height: selectionFrame.height)
            )
                
            context.fill(fillRect)
            context.restoreGState()
            return true
        }
    }

    open func drawBackground(in rect: NSRect) {
        guard drawsBackground, let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
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
            context.addLines(between: [CGPoint(x: requiredThickness, y: 0), CGPoint(x: requiredThickness, y: frame.maxY) ])
            context.strokePath()
        }
        
        // Needs to run before adding the lines, since it will not be set as the background otherwise
        if highlightSelectedLine {
            drawHighlightedRuler(context, relativePoint, in: dirtyRect)
        }

        context.textMatrix = CGAffineTransform(scaleX: 1, y: isFlipped ? -1 : 1)

        for line in lines where dirtyRect.inset(dy: -font.pointSize).contains(line.textPosition.moved(dx: 0, dy: relativePoint.y)) {
            context.textPosition = line.textPosition.moved(dx: 0, dy: relativePoint.y)
            CTLineDraw(line.ctLine, context)
        }

        context.restoreGState()
    }
    
}
