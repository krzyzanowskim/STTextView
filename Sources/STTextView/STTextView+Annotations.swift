import Cocoa

extension STTextView {

    public class LineAnnotation: NSObject {

        /// Location in content storage
        public let location: NSTextLocation

        public init(location: NSTextLocation) {
            self.location = location
        }
    }

    public func addAnnotation(_ annotations: LineAnnotation...) {
        lineAnnotations.append(contentsOf: annotations)
        needsLayout = true
    }

    internal func updateLineAnnotations() {
        lineAnnotationLayer.sublayers = lineAnnotations.compactMap { lineAnnotation in
            if let textLineFragment = textLayoutManager.textLineFragment(at: lineAnnotation.location) {
                return delegate?.textView?(self, viewForLineAnnotation: lineAnnotation, textLineFragment: textLineFragment)
            }

            return nil
        }
    }
}
