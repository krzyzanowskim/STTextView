//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView: NSTextLayoutOrientationProvider {
    public var layoutOrientation: NSLayoutManager.TextLayoutOrientation {
        switch textLayoutManager.textLayoutOrientation(at: textLayoutManager.documentRange.location) {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        @unknown default:
            return textContainer.layoutOrientation
        }
    }
}
