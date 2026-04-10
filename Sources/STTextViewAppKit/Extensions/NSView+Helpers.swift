//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension NSView {
    func findParentView<T: NSView>(of type: T.Type) -> T? {
        var currentSuperview = superview
        while let view = currentSuperview {
            if let parentView = view as? T {
                return parentView
            }
            currentSuperview = view.superview
        }

        return nil
    }

    func findParentTextView() -> STTextView? {
        findParentView(of: STTextView.self)
    }
}
