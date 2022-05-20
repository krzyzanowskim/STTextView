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
        updateLineAnnotations()
    }

    public func removeAnnotation(_ annotations: LineAnnotation...) {
        lineAnnotations.removeAll(where: { annotations.contains($0) })
        updateLineAnnotations()
    }

    public func removeAllAnnotations() {
        lineAnnotations.removeAll(keepingCapacity: true)
        updateLineAnnotations()
    }

    internal func updateLineAnnotations() {
        subviews = lineAnnotations.compactMap { lineAnnotation -> NSView? in
            if let textLineFragment = textLayoutManager.textLineFragment(at: lineAnnotation.location) {
                return delegate?.textView?(self, viewForLineAnnotation: lineAnnotation, textLineFragment: textLineFragment)
            }

            return nil
        }
    }
}
