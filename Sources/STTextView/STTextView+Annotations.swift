//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

/// Line annotation entity.
/// Usually work with subclass that carry more information about the annotation
/// needed for the annotation view
open class STLineAnnotation: NSObject {

    internal var view: NSView?

    /// Location in content storage
    public let location: NSTextLocation

    public init(location: NSTextLocation) {
        self.location = location
    }
}

extension STTextView {

    public func addAnnotation(_ annotations: STLineAnnotation...) {
        self.annotations.append(contentsOf: annotations)
        needsAnnotationsLayout = true
    }

    public func removeAnnotation(_ annotations: STLineAnnotation...) {
        self.annotations.removeAll {
            annotations.contains($0)
        }
        needsAnnotationsLayout = true
    }

    public func removeAllAnnotations() {
        annotations.removeAll(keepingCapacity: true)
        needsAnnotationsLayout = true
    }

    internal func updateLineAnnotationViews() {
        let lineAnnotations = annotations
            .filter { lineAnnotation in
                textLayoutManager.textViewportLayoutController.viewportRange?.contains(lineAnnotation.location) ?? false
            }

        if let delegate = delegate {
            for lineAnnotation in lineAnnotations {
                if let textLineFragment = textLayoutManager.textLineFragment(at: lineAnnotation.location) {
                    textLayoutManager.ensureLayout(for: NSTextRange(location: lineAnnotation.location))
                    lineAnnotation.view = delegate.textView(self, viewForLineAnnotation: lineAnnotation, textLineFragment: textLineFragment)
                }
            }
        }

        subviews = lineAnnotations.compactMap(\.view)
    }
}
