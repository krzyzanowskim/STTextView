//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import CoreGraphics
import STTextViewCommon

@available(*, deprecated, renamed: "STTextRenderView")
public typealias STTextLayoutRangeView = STTextRenderView

/// A view with content of range.
/// Used to provide image of a text eg. for dragging
open class STTextRenderView: NSView {
    private let textLayoutManager: NSTextLayoutManager
    private let textRange: NSTextRange

    override public var isFlipped: Bool {
        #if os(macOS)
            true
        #else
            false
        #endif
    }

    public var clipsToContent = false

    override open var intrinsicContentSize: NSSize {
        bounds.size
    }

    public init(textLayoutManager: NSTextLayoutManager, textRange: NSTextRange) {
        self.textLayoutManager = textLayoutManager
        self.textRange = textRange

        super.init(frame: .zero)
        wantsLayer = true
        needsLayout = true
    }

    override open func layout() {
        // Calculate frame. Expand to the size of layout fragments in the asked range
        textLayoutManager.ensureLayout(for: textRange)

        var frameWidth: CGFloat = 0
        var frameMinY: CGFloat = .greatestFiniteMagnitude
        var frameMaxY: CGFloat = 0

        textLayoutManager.enumerateTextLayoutFragments(in: textRange) { textLayoutFragment in
            let fragmentFrame = textLayoutFragment.layoutFragmentFrame
            frameWidth = max(frameWidth, fragmentFrame.maxX + textLayoutFragment.leadingPadding + textLayoutFragment.trailingPadding)
            frameMinY = min(frameMinY, fragmentFrame.minY)
            frameMaxY = max(frameMaxY, fragmentFrame.maxY)
            return true
        }

        let frameHeight = frameMaxY - (clipsToContent ? frameMinY : 0)
        self.frame = CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight)

        super.layout()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func image() -> NSImage? {
        layoutSubtreeIfNeeded()
        return stImage()
    }

    override open func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // When clipsToContent is true, we need to offset all positions so content starts at y=0
        var firstFragmentMinY: CGFloat?

        textLayoutManager.enumerateTextLayoutFragments(in: textRange) { textLayoutFragment in
            let fragmentFrame = textLayoutFragment.layoutFragmentFrame

            // Track the first fragment's y position for clipsToContent offset
            if firstFragmentMinY == nil {
                firstFragmentMinY = fragmentFrame.minY
            }

            // Calculate the base origin for this layout fragment
            let fragmentOrigin: CGPoint
            if clipsToContent {
                fragmentOrigin = CGPoint(
                    x: fragmentFrame.origin.x,
                    y: fragmentFrame.origin.y - (firstFragmentMinY ?? 0)
                )
            } else {
                fragmentOrigin = fragmentFrame.origin
            }

            for textLineFragment in textLayoutFragment.textLineFragments {
                guard let textLineFragmentRange = textLineFragment.textRange(in: textLayoutFragment) else {
                    continue
                }

                // Apply lineHeightMultiple offset to match STTextLayoutFragment rendering
                let paragraphStyle: NSParagraphStyle = if !textLineFragment.isExtraLineFragment,
                                                          let lineParagraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                    lineParagraphStyle
                } else {
                    .default
                }
                let lineHeightOffset = -(textLineFragment.typographicBounds.height * (paragraphStyle.stLineHeightMultiple - 1.0) / 2)

                // Draw at fragment origin + line fragment's relative position (from typographicBounds.origin)
                let drawOrigin = CGPoint(
                    x: fragmentOrigin.x + textLineFragment.typographicBounds.origin.x,
                    y: fragmentOrigin.y + textLineFragment.typographicBounds.origin.y + lineHeightOffset
                )
                textLineFragment.draw(at: drawOrigin, in: ctx)

                // if textLineFragment contains textRange.location, cut off everything before it
                if textLineFragmentRange.contains(textRange.location) {
                    let originOffset = textLineFragment.locationForCharacter(at: textLayoutManager.offset(from: textLineFragmentRange.location, to: textRange.location))
                    ctx.clear(CGRect(x: drawOrigin.x, y: drawOrigin.y, width: originOffset.x, height: textLineFragment.typographicBounds.height))
                }

                if textLineFragmentRange.contains(textRange.endLocation) {
                    let originOffset = textLineFragment.locationForCharacter(at: textLayoutManager.offset(from: textLineFragmentRange.location, to: textRange.endLocation))
                    ctx.clear(CGRect(x: drawOrigin.x + originOffset.x, y: drawOrigin.y, width: textLineFragment.typographicBounds.width - originOffset.x, height: textLineFragment.typographicBounds.height))
                    break
                }
            }

            return true
        }
    }
}
