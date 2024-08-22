//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import CoreGraphics
import STTextKitPlus

final class STTextLayoutFragmentView: NSView {
    var layoutFragment: NSTextLayoutFragment {
        didSet {
            needsDisplay = true
            needsLayout = true
        }
    }

    override var isFlipped: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    init(layoutFragment: NSTextLayoutFragment, frame: CGRect) {
        self.layoutFragment = layoutFragment
        super.init(frame: frame)
        wantsLayer = true
        clipsToBounds = false // allow overdraw invisible characters
        // layer?.backgroundColor = NSColor.red.withAlphaComponent(0.2).cgColor

        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: CGRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        layoutFragment.draw(at: .zero, in: context)
        drawSpellCheckerAttributes(dirtyRect, in: context)
        context.restoreGState()
    }

    override func layout() {
        super.layout()
        layoutAttachmentView()
    }

    private func layoutAttachmentView() {
        for attachmentViewProvider in layoutFragment.textAttachmentViewProviders {
            guard let attachmentView = attachmentViewProvider.view else {
                continue
            }

            let viewOrig = layoutFragment.frameForTextAttachment(at: attachmentViewProvider.location).origin
            attachmentView.frame.origin = viewOrig
            if attachmentView.superview == nil {
                addSubview(attachmentView)
            }
        }
    }

    private func drawSpellCheckerAttributes(_ dirtyRect: CGRect, in context: CGContext) {
        guard let textLayoutManager = layoutFragment.textLayoutManager else {
            return
        }

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

        textLayoutManager.enumerateRenderingAttributes(in: layoutFragment.rangeInElement, reverse: false) { textLayoutManager, attrs, attrTextRange in
            if let spellingState = attrs[.spellingState] as? String {
                if spellingState == "1" {
                    context.setStrokeColor(NSColor.systemRed.withAlphaComponent(0.8).cgColor)
                } else if spellingState == "2" {
                    context.setStrokeColor(NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor)
                }

                if let segmentFrame = textLayoutManager.textSegmentFrame(in: attrTextRange, type: .standard) {
                    let pointSize: CGFloat = 2.5
                    let frameRect = CGRect(origin: CGPoint(x: segmentFrame.origin.x + pointSize, y: segmentFrame.origin.y - layoutFragment.layoutFragmentFrame.origin.y), size: CGSize(width: segmentFrame.size.width - pointSize, height: segmentFrame.size.height))
                    if frameRect.intersects(dirtyRect) {
                        drawUnderline(under: frameRect, lineWidth: pointSize)
                    }
                }
            }
            return true
        }

        context.restoreGState()
    }

}
