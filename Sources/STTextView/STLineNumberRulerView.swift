//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

public final class STLineNumberRulerView: NSRulerView {
    public override var isFlipped: Bool {
        true
    }

    private var textView: STTextView? {
        clientView as? STTextView
    }

    private var font: NSFont {
        textView?.font ?? NSFont.controlContentFont(ofSize: NSFont.labelFontSize)
    }

    private var lines: [(textPosition: CGPoint, ctLine: CTLine)] = []

    public var textColor: NSColor?

    public init(textView: STTextView, scrollView: NSScrollView) {
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

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func invalidateHashMarks() {
        super.invalidateHashMarks()
        invalidateLineNumbers()
    }

    private func invalidateLineNumbers() {
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor ?? NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph
        ]

        lines.removeAll(keepingCapacity: true)

        var lineNum = 1
        let enumerateStartLocation = textView?.textLayoutManager.documentRange.location
        textView?.textLayoutManager.enumerateTextLayoutFragments(from: enumerateStartLocation, options: [.ensuresLayout, .ensuresExtraLineFragment]) { textLayoutFragment in

            for textLineFragment in textLayoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || textLayoutFragment.textLineFragments.first == textLineFragment) {

                let locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)
                let attributedString = CFAttributedStringCreate(nil, "\(lineNum)" as CFString, attributes as CFDictionary)!
                let ctline = CTLineCreateWithAttributedString(attributedString)

                lines.append(
                    (
                        textPosition: textLayoutFragment.layoutFragmentFrame.pixelAligned.origin.applying(.init(translationX: 4, y: locationForFirstCharacter.y)),
                        ctLine: ctline
                    )
                )

                lineNum += 1
            }

            return true
        }

        // Adjust thickness
        let estimatedWidth = (log10(CGFloat(lineNum)) + 1) * font.boundingRectForFont.width
        if estimatedWidth != ruleThickness {
            ruleThickness = estimatedWidth
        }

    }

    public override func drawHashMarksAndLabels(in rect: NSRect) {
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
