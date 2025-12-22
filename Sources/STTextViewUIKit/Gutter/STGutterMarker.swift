import UIKit

public struct STGutterMarker: Equatable {
    /// Line number
    public let lineNumber: Int

    /// View
    public let view: UIView

    public init(lineNumber: Int, view: UIView) {
        self.lineNumber = lineNumber
        self.view = view
    }

    public init(lineNumber: Int) {
        self.view = MarkerView()
        self.lineNumber = lineNumber
    }
}

private class MarkerView: UIView {
    override init(frame frameRect: CGRect = .zero) {
        super.init(frame: frameRect)
        clipsToBounds = true
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let bezierPath = indicatorPath(size: bounds.size)
        UIColor.tintColor.withAlphaComponent(0.6).setFill()
        bezierPath.fill()
    }

    private func indicatorPath(size: CGSize, inset: CGFloat = 0, flipped: Bool = false) -> UIBezierPath {
        // Original dimensions from SVG
        let originalWidth: CGFloat = 83
        let originalHeight: CGFloat = 38

        // Calculate scale factors, accounting for inset
        let scaleX = (size.width - (inset * 2)) / originalWidth
        let scaleY = (size.height - (inset * 2)) / originalHeight

        let path = UIBezierPath()
        let height: CGFloat = originalHeight

        // Helper function to adjust Y coordinate if needed
        func y(_ value: CGFloat) -> CGFloat {
            return flipped ? height - value : value
        }

        // Start point and first curve
        path.move(to: CGPoint(x: 0, y: y(3)))
        path.addCurve(to: CGPoint(x: 2.97836, y: y(0)),
                      controlPoint1: CGPoint(x: 0, y: y(1.34315)),
                      controlPoint2: CGPoint(x: 1.3215, y: y(0)))

        // Line through middle points to 66,0
        path.addLine(to: CGPoint(x: 66, y: y(0)))

        // Right side curves
        path.addCurve(to: CGPoint(x: 73.5, y: y(3.5)),
                      controlPoint1: CGPoint(x: 69, y: y(0)),
                      controlPoint2: CGPoint(x: 70.8165, y: y(1.35322)))

        path.addCurve(to: CGPoint(x: 82.5, y: y(18.5)),
                      controlPoint1: CGPoint(x: 76.1835, y: y(5.64678)),
                      controlPoint2: CGPoint(x: 82.5, y: y(13.5)))

        path.addCurve(to: CGPoint(x: 73.5, y: y(34)),
                      controlPoint1: CGPoint(x: 82.5, y: y(23.5)),
                      controlPoint2: CGPoint(x: 75.5, y: y(32)))

        path.addCurve(to: CGPoint(x: 66, y: y(38)),
                      controlPoint1: CGPoint(x: 71.5, y: y(36)),
                      controlPoint2: CGPoint(x: 69, y: y(38)))

        // Line back through middle points
        path.addLine(to: CGPoint(x: 2.97836, y: y(38)))

        // Final curve to close the path
        path.addCurve(to: CGPoint(x: 0, y: y(35)),
                      controlPoint1: CGPoint(x: 1.32151, y: y(38)),
                      controlPoint2: CGPoint(x: 0, y: y(36.6569)))

        path.addLine(to: CGPoint(x: 0, y: y(3)))
        path.close()

        // Create transform
        let transform = CGAffineTransform.identity
            .scaledBy(x: scaleX, y: scaleY)
            .translatedBy(x: inset / scaleX, y: inset / scaleY)

        // Apply the transform
        path.apply(transform)

        return path
    }

}
