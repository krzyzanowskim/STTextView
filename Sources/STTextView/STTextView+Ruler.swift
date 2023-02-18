//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    public func toggleRuler(_ sender: Any?) {
        isRulerVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    public var isRulerVisible: Bool {
        set {
            enclosingScrollView?.rulersVisible = newValue
        }
        get {
            enclosingScrollView?.rulersVisible ?? false
        }
    }

    open override func rulerView(_ ruler: NSRulerView, handleMouseDownWith event: NSEvent) {
        guard isRulerVisible else {
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        guard let textLayoutFragment = textLayoutManager.textLayoutFragment(for: point) else {
            return
        }

        var baselineOffset: CGFloat = 0
        if let paragraphStyle = defaultParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
            baselineOffset = -(typingLineHeight * (defaultParagraphStyle!.lineHeightMultiple - 1.0) / 2)
        }

        let effectiveFrame = textLayoutFragment.layoutFragmentFrame.moved(dy: baselineOffset)

        let existingMarkers = (ruler.markers ?? []).filter { marker in
            marker.imageRectInRuler.intersects(textLayoutFragment.layoutFragmentFrame)
        }

        if existingMarkers.isEmpty {
            let marker = STRulerMarker(rulerView: ruler, markerLocation: effectiveFrame.maxY)
            ruler.addMarker(marker)
        } else {
            existingMarkers.forEach(ruler.removeMarker)
            ruler.needsDisplay = true
        }

    }
}
