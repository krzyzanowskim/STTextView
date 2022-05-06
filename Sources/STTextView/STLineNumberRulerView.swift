//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

open class STLineNumberRulerView: NSRulerView {

    private var textView: STTextView? {
        clientView as? STTextView
    }

    open var font: NSFont {
        textView?.font ?? NSFont.controlContentFont(ofSize: NSFont.labelFontSize)
    }

    @Invalidating(.display)
    open var rulePadding: CGFloat = 6

    @Invalidating(.display)
    open var textColor: NSColor = .secondaryLabelColor

    @Invalidating(.display)
    open var drawSeparator: Bool = true

    @Invalidating(.display)
    open var backgroundColor: NSColor = NSColor.controlBackgroundColor

    private var lines: [(textPosition: CGPoint, ctLine: CTLine)] = []

    public required init(textView: STTextView, scrollView: NSScrollView) {
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

        textView?.textLayoutManager.enumerateTextLayoutFragments(from: textView?.textLayoutManager.documentRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { textLayoutFragment in

            for textLineFragment in textLayoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || textLayoutFragment.textLineFragments.first == textLineFragment) {
                let locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)
                let attributedString = CFAttributedStringCreate(nil, "\(lines.count + 1)" as CFString, attributes as CFDictionary)!
                let ctLine = CTLineCreateWithAttributedString(attributedString)

                lines.append(
                    (
                        textPosition: textLayoutFragment.layoutFragmentFrame.origin.moved(dx: 0, dy: locationForFirstCharacter.y),
                        ctLine: ctLine
                    )
                )
            }

            return true
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
                textPosition: $0.textPosition.moved(dx: ruleThickness - (ctLineWidth + rulePadding), dy: 0),
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
            context.setStrokeColor(NSColor.separatorColor.cgColor)
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
