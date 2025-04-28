//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import AppKit

extension STTextView {

    open override func scroll(_ point: NSPoint) {
        contentView.scroll(point.applying(.init(translationX: -(gutterView?.frame.width ?? 0), y: 0)))
    }

    @discardableResult
    internal func scrollToVisible(_ selectionTextRange: NSTextRange, type: NSTextLayoutManager.SegmentType) -> Bool {
        guard var rect = textLayoutManager.textSegmentFrame(in: selectionTextRange, type: type) else {
            return false
        }

        if rect.width.isZero {
            // add padding around the point to ensure the visibility the segment
            // since the width of the segment is 0 for a selection
            rect = rect.inset(by: .init(top: 0, left: -textContainer.lineFragmentPadding, bottom: 0, right: -textContainer.lineFragmentPadding))
        }

        // scroll to visible IN clip view (ignoring gutter view overlay)
        // adjust rect to mimick it's size to include gutter overlay
        rect.origin.x -= gutterView?.frame.width ?? 0
        rect.size.width += gutterView?.frame.width ?? 0
        return contentView.scrollToVisible(rect)
    }

    open override func centerSelectionInVisibleArea(_ sender: Any?) {
        guard let selectionTextRange = textLayoutManager.textSelections.last?.textRanges.last,
              var rect = textLayoutManager.textSegmentFrame(in: selectionTextRange, type: .selection) else {
            return
        }

        if rect.width.isZero {
            // add padding around the point to ensure the visibility the segment
            // since the width of the segment is 0 for a selection
            rect = rect.inset(by: .init(top: 0, left: -textContainer.lineFragmentPadding, bottom: 0, right: -textContainer.lineFragmentPadding))
        }

        // scroll to visible IN clip view (ignoring gutter view overlay)
        // adjust rect to mimick it's size to include gutter overlay
        rect.origin.x -= gutterView?.frame.width ?? 0
        rect.size.width += gutterView?.frame.width ?? 0

        // put rect origin in the center
        contentView.scroll(rect.origin.applying(.init(translationX: 0, y: -visibleRect.height / 2)))
    }

    open override func pageUp(_ sender: Any?) {
        scrollPageUp(sender)
    }

    open override func pageUpAndModifySelection(_ sender: Any?) {
        pageUp(sender)
    }

    open override func pageDown(_ sender: Any?) {
        scrollPageDown(sender)
    }

    open override func pageDownAndModifySelection(_ sender: Any?) {
        pageDown(sender)
    }

    open override func scrollPageDown(_ sender: Any?) {
        scroll(visibleRect.moved(dy: visibleRect.height).origin)
    }

    open override func scrollPageUp(_ sender: Any?) {
        scroll(visibleRect.moved(dy: -visibleRect.height).origin)
    }

    open override func scrollToBeginningOfDocument(_ sender: Any?) {
        scroll(CGPoint(x: visibleRect.origin.x, y: frame.minY))
    }

    open override func scrollToEndOfDocument(_ sender: Any?) {
        scroll(CGPoint(x: visibleRect.origin.x, y: frame.maxY))
    }
}
