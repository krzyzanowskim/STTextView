//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
import Cocoa

public struct STGutterMarker: Equatable {
    /// Line number
    public let lineNumber: Int

    /// View
    public let view: NSView

    public init(lineNumber: Int, view: NSView) {
        self.lineNumber = lineNumber
        self.view = view
    }

    public init(lineNumber: Int) {
        self.view = MarkerView()
        self.lineNumber = lineNumber
    }
}

private class MarkerView: NSView {
    override init(frame frameRect: NSRect = .zero) {
        super.init(frame: frameRect)
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bezierPath = indicatorPath(size: bounds.size)
        NSColor.controlAccentColor.withAlphaComponent(0.6).setFill()
        bezierPath.fill()
    }

    private func indicatorPath(size: CGSize, inset: CGFloat = 1) -> NSBezierPath {
        // Original dimensions from SVG
        let originalWidth: CGFloat = 83
        let originalHeight: CGFloat = 38

        // Calculate scale factors, accounting for inset
        let scaleX = (size.width - (inset * 2)) / originalWidth
        let scaleY = (size.height - (inset * 2)) / originalHeight

        let path = NSBezierPath()
        let height: CGFloat = originalHeight

        // Helper function to adjust Y coordinate if needed
        func y(_ value: CGFloat) -> CGFloat {
            return isFlipped ? height - value : value
        }

        // Start point and first curve
        path.move(to: NSPoint(x: 0, y: y(3)))
        path.curve(to: NSPoint(x: 2.97836, y: y(0)),
                   controlPoint1: NSPoint(x: 0, y: y(1.34315)),
                   controlPoint2: NSPoint(x: 1.3215, y: y(0)))

        // Line through middle points to 66,0
        path.line(to: NSPoint(x: 66, y: y(0)))

        // Right side curves
        path.curve(to: NSPoint(x: 73.5, y: y(3.5)),
                   controlPoint1: NSPoint(x: 69, y: y(0)),
                   controlPoint2: NSPoint(x: 70.8165, y: y(1.35322)))

        path.curve(to: NSPoint(x: 82.5, y: y(18.5)),
                   controlPoint1: NSPoint(x: 76.1835, y: y(5.64678)),
                   controlPoint2: NSPoint(x: 82.5, y: y(13.5)))

        path.curve(to: NSPoint(x: 73.5, y: y(34)),
                   controlPoint1: NSPoint(x: 82.5, y: y(23.5)),
                   controlPoint2: NSPoint(x: 75.5, y: y(32)))

        path.curve(to: NSPoint(x: 66, y: y(38)),
                   controlPoint1: NSPoint(x: 71.5, y: y(36)),
                   controlPoint2: NSPoint(x: 69, y: y(38)))

        // Line back through middle points
        path.line(to: NSPoint(x: 2.97836, y: y(38)))

        // Final curve to close the path
        path.curve(to: NSPoint(x: 0, y: y(35)),
                   controlPoint1: NSPoint(x: 1.32151, y: y(38)),
                   controlPoint2: NSPoint(x: 0, y: y(36.6569)))

        path.line(to: NSPoint(x: 0, y: y(3)))
        path.close()

        // Create transforms
        let scaleTransform = AffineTransform(scaleByX: scaleX, byY: scaleY)
        let translateTransform = AffineTransform(translationByX: inset, byY: inset)

        // Combine transforms
        var transform = AffineTransform.identity
        transform.append(scaleTransform)
        transform.append(translateTransform)

        // Apply the transform
        path.transform(using: transform)

        return path
    }


}
