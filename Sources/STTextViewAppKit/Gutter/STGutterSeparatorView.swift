//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

class STGutterSeparatorView: NSView {
    @Invalidating(.display)
    var drawSeparator: Bool = true

    @Invalidating(.display)
    var separatorColor = NSColor.separatorColor.withAlphaComponent(0.1)

    public override func makeBackingLayer() -> CALayer {
        CATiledLayer()
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        if drawSeparator {
            context.setLineWidth(1)
            context.setStrokeColor(separatorColor.cgColor)
            context.addLines(between: [CGPoint(x: frame.width - 0.5, y: 0), CGPoint(x: frame.width - 0.5, y: bounds.maxY) ])
            context.strokePath()
        }
    }
}
