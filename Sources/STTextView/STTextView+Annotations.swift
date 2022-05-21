import Cocoa

public class STLineAnnotation: NSObject {

    /// Location in content storage
    public let location: NSTextLocation

    public init(location: NSTextLocation) {
        self.location = location
    }
}

extension STTextView {

    public func addAnnotation(_ annotations: STLineAnnotation...) {
        lineAnnotations.append(contentsOf: annotations)
        updateLineAnnotations()
    }

    public func removeAnnotation(_ annotations: STLineAnnotation...) {
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
