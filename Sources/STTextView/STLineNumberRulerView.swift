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

    private var lines: [(textPosition: CGPoint, ctLine: CTLine)] = []

    @Invalidating(.display)
    public var textColor: NSColor = .secondaryLabelColor

    public required init(textView: STTextView, scrollView: NSScrollView) {
        super.init(scrollView: scrollView, orientation: .verticalRuler)

        clientView = textView

        NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: textView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }

    }

    open override func invalidateHashMarks() {
        super.invalidateHashMarks()
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func invalidateLineNumbers() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        var linesTmp = lines
        linesTmp.removeAll(keepingCapacity: true)

        textView?.textLayoutManager.enumerateTextLayoutFragments(from: textView?.textLayoutManager.documentRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { textLayoutFragment in

            for textLineFragment in textLayoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || textLayoutFragment.textLineFragments.first == textLineFragment) {
                let locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)
                let attributedString = CFAttributedStringCreate(nil, "\(linesTmp.count + 1)" as CFString, attributes as CFDictionary)!
                let ctLine = CTLineCreateWithAttributedString(attributedString)

                linesTmp.append(
                    (
                        textPosition: textLayoutFragment.layoutFragmentFrame.origin.applying(.init(translationX: 0, y: locationForFirstCharacter.y)),
                        ctLine: ctLine
                    )
                )
            }

            return true
        }

        // Adjust ruleThickness based on last (longest) value
        if let lastLine = linesTmp.last {
            let ctLineWidth = CTLineGetTypographicBounds(lastLine.ctLine, nil, nil, nil)
            if ruleThickness < (ctLineWidth + (rulePadding * 2)) {
                ruleThickness = max(ruleThickness, ctLineWidth + (rulePadding * 2))
            }
        }

        // align to right
        lines = linesTmp.map {
            let ctLineWidth = ceil(CTLineGetTypographicBounds($0.ctLine, nil, nil, nil))

            return (
                textPosition: $0.textPosition.applying(.init(translationX: ruleThickness - (ctLineWidth + rulePadding), y: 0)),
                ctLine: $0.ctLine
            )
        }
    }

    open override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let textView = textView
        else {
            return
        }

        // Invalidate on each drawing is not the best
        // however otherwise there's out of sync (sic)
        // and as drawHashMarksAndLabels draws in parts
        // drawing is borken. TODO: take rect into account
        // and invalidate only visible part
        invalidateLineNumbers()

        let relativePoint = self.convert(NSZeroPoint, from: textView)

        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: isFlipped ? -1 : 1)

        for line in lines {
            context.textPosition = line.textPosition.applying(.init(translationX: 0, y: relativePoint.y))
            CTLineDraw(line.ctLine, context)
        }

        context.restoreGState()
    }
}
