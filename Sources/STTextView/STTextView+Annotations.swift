//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

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
        needsAnnotationsLayout = true
    }

    public func removeAnnotation(_ annotations: STLineAnnotation...) {
        for annotation in annotations {
            annotationViewMap.object(forKey: annotation)?.removeFromSuperview()
            annotationViewMap.removeObject(forKey: annotation)
        }

        self.annotations.removeAll { annotation in
            annotations.contains(annotation)
        }
    }

    public func removeAllAnnotations() {
        for annotation in self.annotations {
            annotationViewMap.object(forKey: annotation)?.removeFromSuperview()
            annotationViewMap.removeObject(forKey: annotation)
        }
        annotations.removeAll(keepingCapacity: true)
    }

    internal func layoutAnnotationViews() {
        guard let delegate = delegate else {
            return
        }

        for annotation in self.annotations {
            textLayoutManager.ensureLayout(for: NSTextRange(location: annotation.location))
            if let textLineFragment = textLayoutManager.textLineFragment(at: annotation.location) {
                if let annotationView = delegate.textView(self, viewForLineAnnotation: annotation, textLineFragment: textLineFragment) {
                    annotationViewMap.object(forKey: annotation)?.removeFromSuperview()
                    annotationViewMap.setObject(annotationView, forKey: annotation)
                    addSubview(annotationView)
                } else {
                    assertionFailure()
                }
            }
        }
    }
}
