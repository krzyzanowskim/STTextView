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
    /// The block receives (decoration, frame, decorationIndex, isFirstSegment) where:
    /// - decorationIndex is for tracking which decoration this is
    /// - isFirstSegment is true only for the very first segment of the decoration
    private func enumerateAnnotationSegments(
        matching filter: (STAnnotationStyle) -> Bool,
        in dirtyRect: CGRect,
        using block: (STAnnotationDecoration, CGRect, Int, Bool) -> Void
    ) {
        guard let textLayoutManager = layoutFragment.textLayoutManager,
              let textContentManager = textLayoutManager.textContentManager,
              let textView = findParentTextView(),
              !textView.annotationDecorations.isEmpty else {
            return
        }

        // Get the fragment's range in the document
        let fragmentRange = layoutFragment.rangeInElement

        // Convert fragment range to NSRange for comparison
        let documentRange = textContentManager.documentRange
        let fragmentStart = textContentManager.offset(from: documentRange.location, to: fragmentRange.location)
        let fragmentEnd = textContentManager.offset(from: documentRange.location, to: fragmentRange.endLocation)
        let fragmentNSRange = NSRange(location: fragmentStart, length: fragmentEnd - fragmentStart)

        // Decorations are sorted by range.location, so we can exit early
        var decorationIndex = 0
        for decoration in textView.annotationDecorations {
            // Early exit: if decoration starts after fragment ends, no more can intersect
            if decoration.range.location >= fragmentNSRange.location + fragmentNSRange.length {
                break
            }

            // Filter by style type
            guard filter(decoration.style) else { continue }

            // Check if this decoration intersects with the fragment's range
            let intersectionRange = NSIntersectionRange(fragmentNSRange, decoration.range)
            guard intersectionRange.length > 0 else {
                decorationIndex += 1
                continue
            }

            // Convert NSRange back to NSTextRange for the intersection
            guard let startLocation = textContentManager.location(documentRange.location, offsetBy: intersectionRange.location),
                  let endLocation = textContentManager.location(startLocation, offsetBy: intersectionRange.length),
                  let textRange = NSTextRange(location: startLocation, end: endLocation) else {
                decorationIndex += 1
                continue
            }

            let currentIndex = decorationIndex
            // Check if this fragment contains the very start of the decoration
            let decorationStartsInThisFragment = decoration.range.location >= fragmentNSRange.location &&
                decoration.range.location < fragmentNSRange.location + fragmentNSRange.length
            var isFirstSegment = decorationStartsInThisFragment

            // Get the frame for this text segment
            textLayoutManager.enumerateTextSegments(in: textRange, type: .standard, options: []) { _, segmentFrame, _, _ in
                // Convert to fragment-local coordinates (subtract fragment origin for both X and Y)
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

                block(decoration, localFrame, currentIndex, isFirstSegment)
                isFirstSegment = false  // Only first segment gets the marker
                return true
            }

            decorationIndex += 1
        }
    }

    private func drawAnnotationBackgrounds(_ dirtyRect: CGRect, in context: CGContext) {
        context.saveGState()

        enumerateAnnotationSegments(matching: { $0 == .background }, in: dirtyRect) { decoration, localFrame, _, _ in
            context.setFillColor(decoration.color.cgColor)
            let bgRect = localFrame.insetBy(dx: 0, dy: -1)
            let path = NSBezierPath(roundedRect: bgRect, xRadius: decoration.thickness, yRadius: decoration.thickness)
            path.fill()
        }

        context.restoreGState()
    }

    private func drawAnnotationUnderlines(_ dirtyRect: CGRect, in context: CGContext) {
        context.saveGState()

        enumerateAnnotationSegments(matching: { $0 != .background }, in: dirtyRect) { decoration, localFrame, _, isFirstSegment in
            // Use decoration's properties instead of hardcoded values
            let underlineY = localFrame.maxY + decoration.verticalOffset
            let markerSize = max(6, decoration.thickness * 4)  // Proportional to thickness, minimum 6pt

            // Draw underline based on style
            context.setStrokeColor(decoration.color.cgColor)
            context.setLineWidth(decoration.thickness)

            switch decoration.style {
            case .solidUnderline:
                context.move(to: CGPoint(x: localFrame.minX, y: underlineY))
                context.addLine(to: CGPoint(x: localFrame.maxX, y: underlineY))
                context.strokePath()

            case .dashedUnderline:
                context.setLineDash(phase: 0, lengths: [decoration.thickness * 3, decoration.thickness * 2])
                context.move(to: CGPoint(x: localFrame.minX, y: underlineY))
                context.addLine(to: CGPoint(x: localFrame.maxX, y: underlineY))
                context.strokePath()
                context.setLineDash(phase: 0, lengths: [])  // Reset

            case .dottedUnderline:
                context.setLineCap(.round)
                context.setLineDash(phase: 0, lengths: [0, decoration.thickness * 2.5])
                context.move(to: CGPoint(x: localFrame.minX, y: underlineY))
                context.addLine(to: CGPoint(x: localFrame.maxX, y: underlineY))
                context.strokePath()
                context.setLineDash(phase: 0, lengths: [])  // Reset
                context.setLineCap(.butt)

            case .wavyUnderline:
                let path = NSBezierPath()
                let amplitude: CGFloat = decoration.thickness
                let wavelength: CGFloat = decoration.thickness * 4
                var x = localFrame.minX
                path.move(to: CGPoint(x: x, y: underlineY))
                var up = true
                while x < localFrame.maxX {
                    let nextX = min(x + wavelength / 2, localFrame.maxX)
                    let controlY = underlineY + (up ? -amplitude : amplitude)
                    path.curve(to: CGPoint(x: nextX, y: underlineY),
                               controlPoint1: CGPoint(x: x + wavelength / 4, y: controlY),
                               controlPoint2: CGPoint(x: nextX - wavelength / 4, y: controlY))
                    x = nextX
                    up.toggle()
                }
                path.lineWidth = decoration.thickness
                path.stroke()

            case .background:
                break  // Handled in drawAnnotationBackgrounds
            }

            // Only draw marker at the very start of the annotation
            guard isFirstSegment else { return }

            context.setFillColor(decoration.color.cgColor)
            let markerX = localFrame.minX
            let markerY = underlineY

            switch decoration.marker {
            case .circle:
                let rect = CGRect(
                    x: markerX - markerSize / 2,
                    y: markerY - markerSize / 2,
                    width: markerSize,
                    height: markerSize
                )
                context.fillEllipse(in: rect)

            case .square:
                let rect = CGRect(
                    x: markerX - markerSize / 2,
                    y: markerY - markerSize / 2,
                    width: markerSize,
                    height: markerSize
                )
                context.fill(rect)

            case .triangle:
                let halfSize = markerSize / 2
                context.move(to: CGPoint(x: markerX - halfSize, y: markerY - halfSize))
                context.addLine(to: CGPoint(x: markerX + halfSize, y: markerY))
                context.addLine(to: CGPoint(x: markerX - halfSize, y: markerY + halfSize))
                context.closePath()
                context.fillPath()

            case .diamond:
                let halfSize = markerSize / 2
                context.move(to: CGPoint(x: markerX, y: markerY - halfSize))
                context.addLine(to: CGPoint(x: markerX + halfSize, y: markerY))
                context.addLine(to: CGPoint(x: markerX, y: markerY + halfSize))
                context.addLine(to: CGPoint(x: markerX - halfSize, y: markerY))
                context.closePath()
                context.fillPath()
            }
        }

        context.restoreGState()
    }

}
