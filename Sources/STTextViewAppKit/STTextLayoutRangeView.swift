//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import CoreGraphics

/// A view with content of range.
/// Used to provide image of a text eg. for dragging
open class STTextLayoutRangeView: NSView {
    private let textLayoutManager: NSTextLayoutManager
    private let textRange: NSTextRange

    public override var isFlipped: Bool {
#if os(macOS)
        true
#else
        false
#endif
    }

    open override var intrinsicContentSize: NSSize {
        bounds.size
    }

    public init(textLayoutManager: NSTextLayoutManager, textRange: NSTextRange?) {
        self.textLayoutManager = textLayoutManager
        self.textRange = textRange ?? textLayoutManager.documentRange

        // Calculate frame. Expand to the size of layout fragments in the asked range
        var frame: CGRect = textLayoutManager.textSegmentFrame(in: self.textRange, type: .standard)!
        textLayoutManager.enumerateTextLayoutFragments(in: self.textRange) { textLayoutFragment in
            frame = CGRect(
                x: 0,
                y: 0,
                width: max(frame.size.width, textLayoutFragment.layoutFragmentFrame.maxX + textLayoutFragment.leadingPadding + textLayoutFragment.trailingPadding),
                height: max(frame.size.height, textLayoutFragment.layoutFragmentFrame.maxY + textLayoutFragment.topMargin + textLayoutFragment.bottomMargin)
            )
            return true
        }

        super.init(frame: frame)
        wantsLayer = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func image() -> NSImage? {
        stImage()
    }

    open override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        textLayoutManager.enumerateTextLayoutFragments(in: textRange) { textLayoutFragment in
            // at what location start draw the line. the first character is at textRange.location
            // I want to draw just a part of the line fragment, however I can only draw the whole line
            // so remove/delete unnecessary part of the line
            var origin = textLayoutFragment.layoutFragmentFrame.origin
            for textLineFragment in textLayoutFragment.textLineFragments {
                guard let textLineFragmentRange = textLineFragment.textRange(in: textLayoutFragment) else {
                    continue
                }

                textLineFragment.draw(at: origin, in: ctx)

                // if textLineFragment contains textRange.location, cut off everything before it
                if textLineFragmentRange.contains(textRange.location) {
                    let originOffset = textLineFragment.locationForCharacter(at: textLayoutManager.offset(from: textLineFragmentRange.location, to: textRange.location))
                    ctx.clear(CGRect(x: origin.x, y: origin.y, width: originOffset.x, height: textLineFragment.typographicBounds.height))
                }

                if textLineFragmentRange.contains(textRange.endLocation) {
                    let originOffset = textLineFragment.locationForCharacter(at: textLayoutManager.offset(from: textLineFragmentRange.location, to: textRange.endLocation))
                    ctx.clear(CGRect(x: originOffset.x, y: origin.y, width: textLineFragment.typographicBounds.width - originOffset.x, height: textLineFragment.typographicBounds.height))
                    break
                }

                // TODO: Position does not take RTL, Vertical into account
                // let writingDirection = textLayoutManager.baseWritingDirection(at: textRange.location)
                origin.y += textLineFragment.typographicBounds.minY + textLineFragment.glyphOrigin.y
            }

            return true
        }
    }
}
