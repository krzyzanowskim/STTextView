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
        self.annotations.append(contentsOf: annotations)
    }

    public func removeAnnotation(_ annotations: STLineAnnotation...) {
        self.annotations.removeAll(where: { annotations.contains($0) })
    }

    public func removeAllAnnotations() {
        annotations.removeAll(keepingCapacity: true)
    }

    internal func updateLineAnnotations() {
        subviews = annotations.compactMap { lineAnnotation -> NSView? in
            if let textLineFragment = textLayoutManager.textLineFragment(at: lineAnnotation.location) {
                return delegate?.textView?(self, viewForLineAnnotation: lineAnnotation, textLineFragment: textLineFragment)
            }

            return nil
        }
    }
}
