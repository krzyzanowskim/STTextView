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
    open var font: NSFont

    /// The horizontal padding of the ruler view.
    @Invalidating(.display)
    open var leftRulePadding: CGFloat = 6
    
    @Invalidating(.display)
    open var rightRulePadding: CGFloat = 6

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
    open var drawHighlightedRuler: Bool = false
    
    @Invalidating(.display)
    open var highlightRulerBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.25)
    
    @Invalidating(.display)
    open var highlightLineNumberColor: NSColor = .textColor

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

    private var lines: [(textPosition: CGPoint, ctLine: CTLine)] = []
    
    public required init(textView: STTextView, scrollView: NSScrollView) {
        font = textView.font ?? NSFont(descriptor: NSFont.monospacedDigitSystemFont(ofSize: NSFont.labelFontSize, weight: .regular).fontDescriptor.withSymbolicTraits(.condensed), size: NSFont.labelFontSize) ?? NSFont.monospacedSystemFont(ofSize: NSFont.labelFontSize, weight: .regular)

        super.init(scrollView: scrollView, orientation: .verticalRuler)

        clientView = textView

        NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: textView, queue: .main) { [weak self] _ in
            self?.invalidateLineNumbers()
            self?.needsDisplay = true
        }

        NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: textView, queue: .main) { [weak self] _ in
            self?.invalidateLineNumbers()
            self?.needsDisplay = true
        }
        
        NotificationCenter.default.addObserver(forName: STTextView.didChangeSelectionNotification, object: textView.textLayoutManager, queue: .main) { [weak self] _ in
            self?.invalidateLineNumbers()
            self?.needsDisplay = true
        }
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func invalidateLineNumbers() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: highlightLineNumberColor.cgColor
        ]
        lines.removeAll(keepingCapacity: true)

        guard let textLayoutManager = textView?.textLayoutManager else {
            return
        }

        if textLayoutManager.documentRange.isEmpty {
            // For empty document, layout the extra line as if it has text in it
            // the ExtraLineFragment doesn't have information about typing attributes hence layout manager uses a default values - not from text view
            textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { textLayoutFragment in
                for lineFragment in textLayoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || textLayoutFragment.textLineFragments.first == lineFragment) {

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
                        (
                            textPosition: textLayoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y + baselineOffset),
                            ctLine: ctLine
                        )
                    )
                }

                return false
            }
        } else {
            textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { textLayoutFragment in

                for lineFragment in textLayoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || textLayoutFragment.textLineFragments.first == lineFragment) {
                    var baselineOffset: CGFloat = 0

                    if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                        baselineOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                    }

                    let locationForFirstCharacter = lineFragment.locationForCharacter(at: 0)
                    let originPoint = textLayoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y + baselineOffset)
                    let attributedString = NSAttributedString(string: "\(lines.count + 1)", attributes: determineLineNumberAttribute(originPoint.y, attributes, highlightWith: highlightAttributes))
                    let ctLine = CTLineCreateWithAttributedString(attributedString)

                    lines.append(
                        (
                            textPosition: textLayoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y + baselineOffset),
                            ctLine: ctLine
                        )
                    )
                }

                return true
            }
        }

        // Adjust ruleThickness based on last (longest) value
        if let lastLine = lines.last {
            let ctLineWidth = CTLineGetTypographicBounds(lastLine.ctLine, nil, nil, nil)
            if ruleThickness < (ctLineWidth + (leftRulePadding + rightRulePadding)) {
                self.ruleThickness = max(self.ruleThickness, ctLineWidth + (leftRulePadding + rightRulePadding))
            }
        }

        // align to right
        lines = lines.map {
            let ctLineWidth = ceil(CTLineGetTypographicBounds($0.ctLine, nil, nil, nil))

            return (
                textPosition: $0.textPosition.moved(dx: ruleThickness - (ctLineWidth + rightRulePadding), dy: -baselineOffset),
                ctLine: $0.ctLine
            )
        }
    }
    
    // Return text attributes depending on whether the ruleline is highlighted or not.
    private func determineLineNumberAttribute(_ yPosition: CGFloat, _ attributes: [NSAttributedString.Key: Any],
                                              highlightWith highlightAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let textLayoutManager = textView?.textLayoutManager,
              let caretLocation = textLayoutManager.insertionPointLocation,
              drawHighlightedRuler == true
        else {
            return attributes
        }
       var attr = attributes
        // Get the current highlight frame of the textContainer
        textLayoutManager.enumerateTextSegments(in: NSTextRange(location: caretLocation), type: .highlight) { _, textSegmentFrame, _, _ -> Bool in
            // If the y-coordinate of the Ctline is in between the top and bottom edge of the highlight frame, then that ruler line has to be highlighted.
            if textSegmentFrame.origin.y < yPosition && ((textSegmentFrame.origin.y + textSegmentFrame.height) > yPosition) {
                attr = highlightAttributes
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
            context.setFillColor(highlightRulerBackgroundColor.cgColor)
                
            let originPoint = CGPoint(x: frame.minX, y: selectionFrame.origin.y).moved(dx: 0, dy: relativePoint.y)

            // Create background rectangle for highlight
            let fillRect = CGRect(
            origin: originPoint,
            size: CGSize(
                width: frame.width,
                height: selectionFrame.height
                )
            )
                
            context.fill(fillRect)
            context.restoreGState()
            return true
        }
    }

    open override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext, let textView = textView else { return }

        let relativePoint = self.convert(NSZeroPoint, from: textView)

        context.saveGState()

        context.setFillColor(backgroundColor.cgColor)
        context.fill(bounds)

        if drawSeparator {
            context.setLineWidth(1)
            context.setStrokeColor(separatorColor.cgColor)
            context.addLines(between: [CGPoint(x: ruleThickness, y: 0), CGPoint(x: ruleThickness, y: frame.maxY) ])
            context.strokePath()
        }
        
        // Needs to run before adding the lines, since it will not be set as the background otherwise
        if drawHighlightedRuler {
            drawHighlightedRuler(context, relativePoint, in: dirtyRect)
        }

        context.textMatrix = CGAffineTransform(scaleX: 1, y: isFlipped ? -1 : 1)

        for line in lines where dirtyRect.inset(dy: -font.pointSize).contains(line.textPosition.moved(dx: 0, dy: relativePoint.y)) {
            context.textPosition = line.textPosition.moved(dx: 0, dy: relativePoint.y)
            CTLineDraw(line.ctLine, context)
        }

        context.restoreGState()

        drawHashMarksAndLabels(in: dirtyRect)

        if let markers = markers, !markers.isEmpty {
            drawMarkers(in: dirtyRect)
        }
    }
}
