//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import CoreGraphics
import STTextKitPlus

final class TextLayoutFragmentView: NSView {
    private let layoutFragment: NSTextLayoutFragment

    override var isFlipped: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    init(layoutFragment: NSTextLayoutFragment, frame: NSRect) {
        self.layoutFragment = layoutFragment
        super.init(frame: frame)
        wantsLayer = true
        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        layoutFragment.draw(at: .zero, in: context)
        drawSpellCheckerAttributes(dirtyRect, in: context)
    }

    private func drawSpellCheckerAttributes(_ dirtyRect: NSRect, in context: CGContext) {

        func drawUnderline(under rect: CGRect, lineWidth: CGFloat) {
            let path = NSBezierPath()
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.setLineDash([0, 3.75], count: 2, phase: 0)
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY - (path.lineWidth)))
            path.line(to: CGPoint(x: rect.maxX, y: rect.maxY - (path.lineWidth)))
            path.stroke()
        }

        context.saveGState()

        layoutFragment.textLayoutManager?.enumerateRenderingAttributes(in: layoutFragment.rangeInElement) { textLayoutManager, attrs, textRange in
            if attrs[.spellingState] != nil {
                // find frame for textRange inside this layoutFragmentFrame
                if let segmentFrame = textLayoutManager.textSegmentFrame(in: textRange, type: .standard) {
                    context.setStrokeColor(NSColor.systemRed.withAlphaComponent(0.8).cgColor)
                    let pointSize: CGFloat = 2.5
                    let frameRect = CGRect(origin: CGPoint(x: segmentFrame.origin.x + pointSize, y: 0), size: CGSize(width: segmentFrame.size.width - pointSize, height: segmentFrame.size.height))
                    drawUnderline(under: frameRect, lineWidth: pointSize)
                }
            }
            return true
        }

        context.restoreGState()
    }
}
