//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension STTextView {

    /// Scrolls the text view to make the specified text range visible.
    /// - Parameters:
    ///   - textRange: The text range to scroll to.
    ///   - type: The type of text segment to use for calculating the visible rect.
    /// - Returns: `true` if the scroll was performed, `false` otherwise.
    @discardableResult
    func scrollToVisible(_ textRange: NSTextRange, type: NSTextLayoutManager.SegmentType) -> Bool {
        guard var rect = textLayoutManager.textSegmentFrame(in: textRange, type: type) else {
            return false
        }

        if rect.width.isZero {
            // Add padding around the point to ensure visibility
            // since the width of the segment is 0 for a caret
            rect = rect.insetBy(dx: -textContainer.lineFragmentPadding, dy: 0)
        }

        // Ensure minimum height for visibility
        if rect.height < typingLineHeight {
            rect.size.height = typingLineHeight
        }

        // Adjust for content view offset
        rect = rect.offsetBy(dx: contentView.frame.origin.x, dy: contentView.frame.origin.y)

        scrollRectToVisible(rect, animated: false)
        return true
    }

    /// Scrolls the selection to be visible, equivalent to UITextView's scrollSelectionToVisible.
    /// - Parameter animated: Whether the scroll should be animated.
    func scrollSelectionToVisible(_ animated: Bool = true) {
        guard let textRange = textLayoutManager.textSelections.last?.textRanges.last else {
            return
        }

        guard var rect = textLayoutManager.textSegmentFrame(in: textRange, type: .standard) else {
            return
        }

        if rect.width.isZero {
            // Add padding for caret visibility
            rect = rect.insetBy(dx: -textContainer.lineFragmentPadding, dy: 0)
        }

        // Ensure minimum dimensions
        rect.size.height = max(rect.size.height, typingLineHeight)
        rect.size.width = max(rect.size.width, 2)

        // Adjust for content view offset
        rect = rect.offsetBy(dx: contentView.frame.origin.x, dy: contentView.frame.origin.y)

        scrollRectToVisible(rect, animated: animated)
    }

    /// Scrolls to make the specified range visible.
    /// - Parameter range: The range to scroll to.
    public func scrollRangeToVisible(_ range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }
        scrollToVisible(textRange, type: .standard)
    }

    /// Scrolls to make the specified text range visible.
    /// - Parameter range: The text range to scroll to.
    public func scrollRangeToVisible(_ range: NSTextRange) {
        scrollToVisible(range, type: .standard)
    }
}
