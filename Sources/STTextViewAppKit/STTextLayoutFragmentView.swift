//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import CoreGraphics
import STTextKitPlus
import STTextViewCommon

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

        if ProcessInfo().environment["ST_LAYOUT_DEBUG"] == "YES" {
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.05).cgColor
            layer?.borderColor = NSColor.systemOrange.cgColor
            layer?.borderWidth = 0.5
        }

        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: CGRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        // Draw backgrounds first (behind text)
        drawAnnotationBackgrounds(dirtyRect, in: context)
        layoutFragment.draw(at: .zero, in: context)
        drawSpellCheckerAttributes(dirtyRect, in: context)
        // Draw underlines after text
        drawAnnotationUnderlines(dirtyRect, in: context)
        context.restoreGState()
    }

    override func layout() {
        super.layout()
        layoutAttachmentView()
    }

    private func layoutAttachmentView() {
        for attachmentViewProvider in layoutFragment.textAttachmentViewProviders {
            guard let attachmentView = attachmentViewProvider.view,
                  let textAttachment = attachmentViewProvider.textAttachment else {
                continue
            }

            let frameForTextAttachment = layoutFragment.frameForTextAttachment(at: attachmentViewProvider.location)
            guard frameForTextAttachment != .zero else {
                continue
            }

            attachmentView.frame = frameForTextAttachment

            if attachmentView.superview == nil {
                addSubview(attachmentView)
                
                // Configure accessibility for attachment views
                configureAccessibilityForAttachmentView(attachmentView, provider: attachmentViewProvider)
                
                // Set up attachment interaction bridge
                if let textView = findParentTextView() {
                    attachmentView.setupAttachmentInteraction(
                        textView: textView,
                        attachment: textAttachment,
                        location: attachmentViewProvider.location
                    )
                }
            }
        }
    }
    
    private func findParentTextView() -> STTextView? {
        var currentView: NSView? = self
        while let parentView = currentView?.superview {
            if let textView = parentView as? STTextView {
                return textView
            }
            currentView = parentView
        }
        return nil
    }
    
    private func configureAccessibilityForAttachmentView(_ attachmentView: NSView, provider: NSTextAttachmentViewProvider) {
        // Set up basic accessibility properties if not already configured
        if attachmentView.accessibilityRole() == nil {
            attachmentView.setAccessibilityRole(.image) // Default role, can be overridden
        }
        
        if attachmentView.accessibilityLabel() == nil {
            // Try to get a meaningful label from the attachment
            if let textAttachment = provider.textAttachment {
                if let _ = textAttachment.contents,
                   let _ = textAttachment.fileType,
                   let fileName = textAttachment.fileWrapper?.filename {
                    attachmentView.setAccessibilityLabel("Attachment: \(fileName)")
                } else {
                    attachmentView.setAccessibilityLabel("Text attachment")
                }
            }
        }
        
        // Ensure the view participates in accessibility
        attachmentView.setAccessibilityElement(true)
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

    // MARK: - Annotation Drawing

    /// Shared logic for getting decorations that intersect this fragment.
    private func enumerateAnnotationSegments(
        matching filter: (STAnnotationStyle) -> Bool,
        in dirtyRect: CGRect,
        using block: (STAnnotationDecoration, CGRect) -> Void
    ) {
        guard let textLayoutManager = layoutFragment.textLayoutManager,
              let textContentManager = textLayoutManager.textContentManager,
              let textView = findParentTextView(),
              !textView.annotationDecorations.isEmpty else {
            return
        }

        // Get the fragment's range in the document
        guard let fragmentRange = layoutFragment.rangeInElement else {
            return
        }

        // Convert fragment range to NSRange for comparison
        let documentRange = textContentManager.documentRange
        guard let fragmentStart = textContentManager.offset(from: documentRange.location, to: fragmentRange.location),
              let fragmentEnd = textContentManager.offset(from: documentRange.location, to: fragmentRange.endLocation) else {
            return
        }
        let fragmentNSRange = NSRange(location: fragmentStart, length: fragmentEnd - fragmentStart)

        for decoration in textView.annotationDecorations {
            // Filter by style type
            guard filter(decoration.style) else { continue }

            // Check if this decoration intersects with the fragment's range
            guard let intersectionRange = fragmentNSRange.intersection(decoration.range),
                  intersectionRange.length > 0 else {
                continue
            }

            // Convert NSRange back to NSTextRange for the intersection
            guard let startLocation = textContentManager.location(documentRange.location, offsetBy: intersectionRange.location),
                  let endLocation = textContentManager.location(startLocation, offsetBy: intersectionRange.length),
                  let textRange = NSTextRange(location: startLocation, end: endLocation) else {
                continue
            }

            // Get the frame for this text segment
            textLayoutManager.enumerateTextSegments(in: textRange, type: .standard, options: []) { _, segmentFrame, _, _ in
                // Convert to fragment-local coordinates
                let localFrame = CGRect(
                    x: segmentFrame.origin.x,
                    y: segmentFrame.origin.y - layoutFragment.layoutFragmentFrame.origin.y,
                    width: segmentFrame.width,
                    height: segmentFrame.height
                )

                // Only process if visible
                guard localFrame.intersects(dirtyRect) else {
                    return true
                }

                block(decoration, localFrame)
                return true
            }
        }
    }

    private func drawAnnotationBackgrounds(_ dirtyRect: CGRect, in context: CGContext) {
        context.saveGState()

        enumerateAnnotationSegments(matching: { $0 == .background }, in: dirtyRect) { decoration, localFrame in
            context.setFillColor(decoration.color.cgColor)
            let bgRect = localFrame.insetBy(dx: 0, dy: -1)
            let path = NSBezierPath(roundedRect: bgRect, xRadius: decoration.thickness, yRadius: decoration.thickness)
            path.fill()
        }

        context.restoreGState()
    }

    private func drawAnnotationUnderlines(_ dirtyRect: CGRect, in context: CGContext) {
        context.saveGState()

        enumerateAnnotationSegments(matching: { $0 != .background }, in: dirtyRect) { decoration, localFrame in
            let underlineY = localFrame.maxY + decoration.verticalOffset
            context.setStrokeColor(decoration.color.cgColor)

            switch decoration.style {
            case .solidUnderline:
                drawSolidUnderline(at: localFrame, y: underlineY, thickness: decoration.thickness, in: context)
            case .dashedUnderline:
                drawDashedUnderline(at: localFrame, y: underlineY, thickness: decoration.thickness, in: context)
            case .dottedUnderline:
                drawDottedUnderline(at: localFrame, y: underlineY, thickness: decoration.thickness, in: context)
            case .wavyUnderline:
                drawWavyUnderline(at: localFrame, y: underlineY, thickness: decoration.thickness, in: context)
            case .background:
                break // Handled separately
            }
        }

        context.restoreGState()
    }

    private func drawSolidUnderline(at rect: CGRect, y: CGFloat, thickness: CGFloat, in context: CGContext) {
        let path = NSBezierPath()
        path.lineWidth = thickness
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.line(to: CGPoint(x: rect.maxX, y: y))
        path.stroke()
    }

    private func drawDashedUnderline(at rect: CGRect, y: CGFloat, thickness: CGFloat, in context: CGContext) {
        let path = NSBezierPath()
        path.lineWidth = thickness
        path.setLineDash([4, 2], count: 2, phase: 0)
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.line(to: CGPoint(x: rect.maxX, y: y))
        path.stroke()
    }

    private func drawDottedUnderline(at rect: CGRect, y: CGFloat, thickness: CGFloat, in context: CGContext) {
        let path = NSBezierPath()
        path.lineWidth = thickness
        path.lineCapStyle = .round
        path.setLineDash([1, 3], count: 2, phase: 0)
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.line(to: CGPoint(x: rect.maxX, y: y))
        path.stroke()
    }

    private func drawWavyUnderline(at rect: CGRect, y: CGFloat, thickness: CGFloat, in context: CGContext) {
        let wavelength: CGFloat = 4
        let amplitude: CGFloat = 1.5
        let path = NSBezierPath()
        path.lineWidth = thickness

        var x = rect.minX
        path.move(to: CGPoint(x: x, y: y))

        while x < rect.maxX {
            let waveY = y + amplitude * sin((x - rect.minX) / wavelength * .pi * 2)
            path.line(to: CGPoint(x: x, y: waveY))
            x += 1
        }

        path.stroke()
    }

}
