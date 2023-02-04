import Cocoa

/// Line annotation entity.
/// Usually work with subclass that carry more information about the annotation
/// needed for the annotation view
open class STLineAnnotation: NSObject {

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
        subviews = annotations
            .filter { lineAnnotation in
                textLayoutManager.textViewportLayoutController.viewportRange?.contains(lineAnnotation.location) ?? false
            }
            .compactMap { lineAnnotation -> NSView? in
                textLayoutManager.ensureLayout(for: NSTextRange(location: lineAnnotation.location))
                if let textLineFragment = textLayoutManager.textLineFragment(at: lineAnnotation.location) {
                    return delegate?.textView(self, viewForLineAnnotation: lineAnnotation, textLineFragment: textLineFragment)
                }

                return nil
            }
    }
}
