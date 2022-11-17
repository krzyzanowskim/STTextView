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
    open var rulePadding: CGFloat = 6

    /// The text color of the line numbers.
    @Invalidating(.display)
    open var textColor: NSColor = .secondaryLabelColor

    /// A Boolean indicating whether to draw a separator or not.
    @Invalidating(.display)
    open var drawSeparator: Bool = true

    /// The background color of the ruler view.
    @Invalidating(.display)
    open var backgroundColor: NSColor = NSColor.controlBackgroundColor

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

    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func invalidateLineNumbers() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
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
                    let attributedString = NSAttributedString(string: "\(lines.count + 1)", attributes: attributes)
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
            if ruleThickness < (ctLineWidth + (rulePadding * 2)) {
                self.ruleThickness = max(self.ruleThickness, ctLineWidth + (self.rulePadding * 2))
            }
        }

        // align to right
        lines = lines.map {
            let ctLineWidth = ceil(CTLineGetTypographicBounds($0.ctLine, nil, nil, nil))

            return (
                textPosition: $0.textPosition.moved(dx: ruleThickness - (ctLineWidth + rulePadding), dy: -baselineOffset),
                ctLine: $0.ctLine
            )
        }
    }

    open override func drawHashMarksAndLabels(in rect: NSRect) {
        //
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
