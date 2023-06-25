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

        let writingDirection = textLayoutManager.baseWritingDirection(at: textRange.location)
        var offsetY: Double = 0
        textLayoutManager.enumerateTextLayoutFragments(from: textRange.location) { textLayoutFragment in
            let shouldContinue = textLayoutFragment.rangeInElement.location <= textRange.endLocation
            if !shouldContinue {
                return false
            }

            // at what location start drawin the line. the first character is at textRange.location
            let firstLineCharacterOffset = max(0, textLayoutManager.offset(from: textLayoutFragment.rangeInElement.location, to: textRange.location))
            for (idx, textLineFragment) in textLayoutFragment.textLineFragments.enumerated() {
                var origin: CGPoint = .zero // adjust to where range start in the line

                if idx == 0 {
                    let p = textLineFragment.locationForCharacter(at: firstLineCharacterOffset)
                    if writingDirection == .leftToRight {
                        origin.x = -p.x
                    } else if writingDirection == .rightToLeft {
                        // FIXME: RTL is incorrect
                        origin.x = p.x
                    }
                }

                textLineFragment.draw(at: CGPoint(x: origin.x, y: origin.y + offsetY), in: ctx)
                offsetY += textLineFragment.typographicBounds.minY + textLineFragment.glyphOrigin.y
            }

            return shouldContinue // Returning false from block breaks out of the enumeration.
        }
    }
}
