//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import CoreGraphics

/// A view with content of range.
/// Used to provide image of a text eg. for dragging
final class TextLayoutRangeView: NSView {
    private let textLayoutManager: NSTextLayoutManager
    private let textRange: NSTextRange

    override var isFlipped: Bool {
#if os(macOS)
        true
#else
        false
#endif
    }

    init(textLayoutManager: NSTextLayoutManager, textRange: NSTextRange) {
        self.textLayoutManager = textLayoutManager
        self.textRange = textRange

        super.init(frame: textLayoutManager.textSelectionSegmentFrame(in: textRange, type: .selection)!)

        wantsLayer = true
        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        var origin: CGPoint = .zero
        textLayoutManager.enumerateTextLayoutFragments(from: textRange.location) { textLayoutFragment in
            let shouldContinue = textLayoutFragment.rangeInElement.location <= textRange.endLocation
            if !shouldContinue {
                return false
            }

            // at what location start draw the line. the first character is at textRange.location
            // I want to draw just a part of the line fragment, however I can only draw the whole line
            // so remove/delete unecessary part of the line
            for textLineFragment in textLayoutFragment.textLineFragments {
                // if textLineFragment contains textRange.location, cut off everything before it
                guard let textLineFragmentRange = textLineFragment.textRange(in: textLayoutFragment) else {
                    continue
                }

                textLineFragment.draw(at: origin, in: ctx)

                if textLineFragmentRange.contains(textRange.location) {
                    let originOffset = textLineFragment.locationForCharacter(at: textLayoutManager.offset(from: textLineFragmentRange.location, to: textRange.location))
                    ctx.clear(CGRect(x: origin.x, y: origin.y, width: originOffset.x, height: textLineFragment.typographicBounds.height))
                }

                if textLineFragmentRange.contains(textRange.endLocation) {
                    let originOffset = textLineFragment.locationForCharacter(at: textLayoutManager.offset(from: textLineFragmentRange.location, to: textRange.endLocation))
                    ctx.clear(CGRect(x: originOffset.x, y: origin.y, width: textLineFragment.typographicBounds.width - originOffset.x, height: textLineFragment.typographicBounds.height))
                }

                // TODO: Position does not take RTL, Vertical into account
                // let writingDirection = textLayoutManager.baseWritingDirection(at: textRange.location)
                origin.y += textLineFragment.typographicBounds.minY + textLineFragment.glyphOrigin.y
            }

            return shouldContinue // Returning false from block breaks out of the enumeration.
        }
    }
}

private extension NSTextLineFragment {

    // Range inside textLayoutFragment relative to the document origin
    func textRange(in textLayoutFragment: NSTextLayoutFragment) -> NSTextRange? {

        guard let textContentManager = textLayoutFragment.textLayoutManager?.textContentManager else {
            assertionFailure()
            return nil
        }

        return NSTextRange(
            location: textContentManager.location(textLayoutFragment.rangeInElement.location, offsetBy: characterRange.location)!,
            end: textContentManager.location(textLayoutFragment.rangeInElement.location, offsetBy: characterRange.location + characterRange.length)
        )
    }
}
