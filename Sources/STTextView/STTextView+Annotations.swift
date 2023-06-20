//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

/// Line annotation entity.
/// Usually work with subclass that carry more information about the annotation
/// needed for the annotation view
open class STLineAnnotation: NSObject {
    /// Location in content storage
    public var location: NSTextLocation

    public init(location: NSTextLocation) {
        self.location = location
    }
}

extension STTextView {

    // Reloads the rows and sections of the table view.
    //
    // Performs the layout for annotation views.
    public func reloadData() {
        layoutAnnotationViewsIfNeeded(forceLayout: true)
    }

    /// Layout annotations views if annotations changed since last time.
    ///
    /// Called from layout()
    internal func layoutAnnotationViewsIfNeeded(forceLayout: Bool = false) {
        guard let dataSource = dataSource else {
            return
        }

        let oldAnnotations = {
            var result: [STLineAnnotation] = []
            result.reserveCapacity(self.annotationViewMap.count)

            let enumerator = self.annotationViewMap.keyEnumerator()
            while let key = enumerator.nextObject() as? STLineAnnotation {
                result.append(key)
            }
            return result
        }()

        let newAnnotations = dataSource.textViewAnnotations(self)
        let change = Set(oldAnnotations).symmetricDifference(Set(newAnnotations))
        if forceLayout || !change.isEmpty {

            for element in change {
                if oldAnnotations.contains(element) {
                    annotationViewMap.object(forKey: element)?.removeFromSuperview()
                    annotationViewMap.removeObject(forKey: element)
                }
            }

            for annotation in newAnnotations {
                textLayoutManager.ensureLayout(for: NSTextRange(location: annotation.location))
                if let textLineFragment = textLayoutManager.textLineFragment(at: annotation.location) {
                    if let annotationView = dataSource.textView(self, viewForLineAnnotation: annotation, textLineFragment: textLineFragment) {
                        // Set or Update view
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
}
