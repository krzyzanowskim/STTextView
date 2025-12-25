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

        // Collect annotation segments once (single enumeration)
        let annotationSegments = collectAnnotationSegments(in: dirtyRect)

        // Draw backgrounds first (behind text)
        drawAnnotationBackgrounds(annotationSegments.backgrounds, in: context)

        layoutFragment.draw(at: .zero, in: context)
        drawSpellCheckerAttributes(dirtyRect, in: context)

        // Draw underlines after text
        drawAnnotationUnderlines(annotationSegments.underlines, in: context)

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

    /// Segments collected from annotation attributes.
    private struct AnnotationSegments {
        var backgrounds: [(STAnnotationRenderAttribute, CGRect)] = []
        var underlines: [(STAnnotationRenderAttribute, CGRect)] = []
    }

    /// Collect annotation segments from text storage attributes.
    ///
    /// Reads annotation render attributes directly from the NSAttributedString,
    /// eliminating the need for a separate decorations array. This method
    /// enumerates attributes once and categorizes segments by style.
    private func collectAnnotationSegments(in dirtyRect: CGRect) -> AnnotationSegments {
        guard let textLayoutManager = layoutFragment.textLayoutManager,
              let textContentManager = textLayoutManager.textContentManager as? NSTextContentStorage,
              let textStorage = textContentManager.textStorage else {
            return AnnotationSegments()
        }

        var segments = AnnotationSegments()

        // Get the fragment's range in the document
        let fragmentRange = layoutFragment.rangeInElement
        let documentRange = textContentManager.documentRange

        // Convert fragment range to NSRange
        let fragmentStart = textContentManager.offset(from: documentRange.location, to: fragmentRange.location)
        let fragmentEnd = textContentManager.offset(from: documentRange.location, to: fragmentRange.endLocation)
        let fragmentNSRange = NSRange(location: fragmentStart, length: fragmentEnd - fragmentStart)

        guard fragmentNSRange.length > 0, fragmentNSRange.location + fragmentNSRange.length <= textStorage.length else {
            return segments
        }

        // Enumerate annotation render attributes in this fragment's range
        textStorage.enumerateAttribute(
            STAnnotationRenderKey,
            in: fragmentNSRange,
            options: []
        ) { value, attrRange, _ in
            guard let box = value as? STAnnotationRenderAttributeBox else {
                return
            }

            let renderAttr = box.attribute

            // attrRange is the full attribute range, which may extend beyond fragmentNSRange
            // We need to use the intersection for proper segment enumeration
            guard let intersectionRange = fragmentNSRange.intersection(attrRange),
                  intersectionRange.length > 0 else {
                return
            }

            // Convert intersection range to NSTextRange for segment enumeration
            guard let startLocation = textContentManager.location(documentRange.location, offsetBy: intersectionRange.location),
                  let endLocation = textContentManager.location(startLocation, offsetBy: intersectionRange.length),
                  let textRange = NSTextRange(location: startLocation, end: endLocation) else {
                return
            }

            // Get the frame for this text segment
            // Note: segmentFrame is in the text container's coordinate space
            textLayoutManager.enumerateTextSegments(in: textRange, type: .standard, options: []) { segmentTextRange, segmentFrame, baselinePosition, _ in
                // Convert from text container coordinates to fragment-local coordinates
                // The view is positioned at layoutFragmentFrame.origin in the text container,
                // so we subtract the fragment origin to get view-local coordinates
                let localFrame = CGRect(
                    x: segmentFrame.origin.x - layoutFragment.layoutFragmentFrame.origin.x,
                    y: segmentFrame.origin.y - layoutFragment.layoutFragmentFrame.origin.y,
                    width: segmentFrame.width,
                    height: segmentFrame.height
                )

                // Only process if visible
                guard localFrame.intersects(dirtyRect) else {
                    return true
                }

                // Categorize by style
                if renderAttr.style == .background {
                    segments.backgrounds.append((renderAttr, localFrame))
                } else {
                    segments.underlines.append((renderAttr, localFrame))
                }

                return true
            }
        }

        return segments
    }

    private func drawAnnotationBackgrounds(_ segments: [(STAnnotationRenderAttribute, CGRect)], in context: CGContext) {
        context.saveGState()

        for (renderAttr, localFrame) in segments {
            context.setFillColor(renderAttr.color.cgColor)
            let bgRect = localFrame.insetBy(dx: 0, dy: -1)
            let path = NSBezierPath(roundedRect: bgRect, xRadius: renderAttr.thickness, yRadius: renderAttr.thickness)
            path.fill()
        }

        context.restoreGState()
    }

    private func drawAnnotationUnderlines(_ segments: [(STAnnotationRenderAttribute, CGRect)], in context: CGContext) {
        context.saveGState()

        for (renderAttr, localFrame) in segments {
            let underlineY = localFrame.maxY + renderAttr.verticalOffset
            context.setStrokeColor(renderAttr.color.cgColor)

            // TODO: Implement marker rendering (renderAttr.marker)

            switch renderAttr.style {
            case .solidUnderline:
                drawSolidUnderline(at: localFrame, y: underlineY, thickness: renderAttr.thickness, in: context)
            case .dashedUnderline:
                drawDashedUnderline(at: localFrame, y: underlineY, thickness: renderAttr.thickness, in: context)
            case .dottedUnderline:
                drawDottedUnderline(at: localFrame, y: underlineY, thickness: renderAttr.thickness, in: context)
            case .wavyUnderline:
                drawWavyUnderline(at: localFrame, y: underlineY, thickness: renderAttr.thickness, in: context)
            case .background:
                break // Handled in drawAnnotationBackgrounds
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
