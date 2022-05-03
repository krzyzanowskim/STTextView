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

    open override func invalidateHashMarks() {
        super.invalidateHashMarks()
        invalidateLineNumbers()
    }

    private func invalidateLineNumbers() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        lines.removeAll(keepingCapacity: true)

        let enumerateStartLocation = textView?.textLayoutManager.documentRange.location
        textView?.textLayoutManager.enumerateTextLayoutFragments(from: enumerateStartLocation, options: [.ensuresLayout, .ensuresExtraLineFragment]) { textLayoutFragment in

            for textLineFragment in textLayoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || textLayoutFragment.textLineFragments.first == textLineFragment) {
                let locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)
                let attributedString = CFAttributedStringCreate(nil, "\(lines.count + 1)" as CFString, attributes as CFDictionary)!
                let ctLine = CTLineCreateWithAttributedString(attributedString)

                lines.append(
                    (
                        textPosition: textLayoutFragment.layoutFragmentFrame.origin.applying(.init(translationX: 0, y: locationForFirstCharacter.y)),
                        ctLine: ctLine
                    )
                )
            }

            return true
        }

        // Adjust ruleThickness based on last (longest) value
        if let lastLine = lines.last {
            let ctLineWidth = CTLineGetTypographicBounds(lastLine.ctLine, nil, nil, nil)
            if ruleThickness < ctLineWidth {
                ruleThickness = ctLineWidth + (rulePadding * 2)
            }
        }

        // align to right
        lines = lines.map {
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
