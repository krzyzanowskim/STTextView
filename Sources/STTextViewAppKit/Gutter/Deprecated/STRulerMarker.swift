//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

@available(*, deprecated, message: "NSRulerView subclass is deprecated")
open class STRulerMarker: NSRulerMarker {

    open var size: CGSize = .zero {
        didSet {
            setSize(size)
        }
    }

    public init(rulerView ruler: NSRulerView, markerLocation location: CGFloat, height: CGFloat = 15) {
        super.init(rulerView: ruler, markerLocation: location, image: NSImage(), imageOrigin: .zero)

        self.size = CGSize(width: ruler.ruleThickness, height: height)
        self.image = NSImage(size: size, flipped: true) { [weak self] rect in
            self?.drawImage(rect)
            return true
        }
    }

    private func setSize(_ newSize: CGSize) {
        image.size = newSize
        ruler?.needsDisplay = true
    }

    @available(*, unavailable)
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func drawImage(_ rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()

        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: rect.height))
        bezierPath.line(to: CGPoint(x: rect.width * 0.85, y: rect.height))
        bezierPath.curve(
            to: CGPoint(x: rect.width, y: rect.height / 2),
            controlPoint1: CGPoint(x: rect.width * 0.85, y: rect.height),
            controlPoint2: CGPoint(x: rect.width, y: rect.height * 0.60)
        )
        bezierPath.curve(
            to: CGPoint(x: rect.width * 0.85, y: 0),
            controlPoint1: CGPoint(x: rect.width, y: rect.height * 0.40 ),
            controlPoint2: CGPoint(x: rect.width * 0.85, y: 0)
        )
        bezierPath.line(to: CGPoint(x: 0, y: 0))
        bezierPath.line(to: CGPoint(x: 0, y: rect.height))
        bezierPath.close()

        NSColor.controlAccentColor.withAlphaComponent(0.7).setFill()
        bezierPath.fill()

        context.restoreGState()

    }
}

