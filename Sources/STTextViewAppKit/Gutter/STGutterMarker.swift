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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bezierPath = indicatorPath(size: bounds.size)
        NSColor.systemBlue.setFill()
        bezierPath.fill()
    }

    private func indicatorPath(size: CGSize, inset: CGFloat = 0) -> NSBezierPath {
        // Original dimensions from SVG
        let originalWidth: CGFloat = 71.25
        let originalHeight: CGFloat = 38

        // Calculate scale factors, accounting for inset
        let scaleX = (size.width - (inset * 2)) / originalWidth
        let scaleY = (size.height - (inset * 2)) / originalHeight

        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 5))
        path.curve(to: NSPoint(x: 5, y: 0), controlPoint1: NSPoint(x: 0, y: 2.24), controlPoint2: NSPoint(x: 2.24, y: 0))
        path.line(to: NSPoint(x: 58.33, y: 0))
        path.curve(to: NSPoint(x: 62.68, y: 2.54), controlPoint1: NSPoint(x: 60.13, y: 0), controlPoint2: NSPoint(x: 61.79, y: 0.97))
        path.line(to: NSPoint(x: 70.6, y: 16.54))
        path.curve(to: NSPoint(x: 70.6, y: 21.46), controlPoint1: NSPoint(x: 71.47, y: 18.06), controlPoint2: NSPoint(x: 71.47, y: 19.94))
        path.line(to: NSPoint(x: 62.68, y: 35.46))
        path.curve(to: NSPoint(x: 58.33, y: 38), controlPoint1: NSPoint(x: 61.79, y: 37.03), controlPoint2: NSPoint(x: 60.13, y: 38))
        path.line(to: NSPoint(x: 5, y: 38))
        path.curve(to: NSPoint(x: 0, y: 33), controlPoint1: NSPoint(x: 2.24, y: 38), controlPoint2: NSPoint(x: 0, y: 35.76))
        path.line(to: NSPoint(x: 0, y: 5))
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
