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
