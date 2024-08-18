//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    @objc public func toggleRuler(_ sender: Any?) {
        isGutterVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    public var isGutterVisible: Bool {
        set {
            if gutterView == nil, newValue == true {
                gutterView = STGutterView()
                if let font {
                    gutterView?.font = adjustGutterFont(font)
                }
                gutterView?.frame.size.width = 40
                if let textColor {
                    gutterView?.selectedLineTextColor = textColor
                }
                gutterView?.highlightSelectedLine = highlightSelectedLine
                gutterView?.selectedLineHighlightColor = selectedLineHighlightColor
                self.addSubview(gutterView!)
            } else if newValue == false {
                gutterView?.removeFromSuperview()
                gutterView = nil
            }
        }
        get {
            gutterView != nil
        }
    }

    // MARK: - NSRulerMarkerClientViewDelegation informal protocol

    open override func rulerView(_ ruler: NSRulerView, willAdd marker: NSRulerMarker, atLocation location: CGFloat) -> CGFloat {
        location
    }

    open override func rulerView(_ ruler: NSRulerView, shouldAdd marker: NSRulerMarker) -> Bool {
        isEditable && ((ruler as? STLineNumberRulerView)?.allowsMarkers ?? true)
    }

    open override func rulerView(_ ruler: NSRulerView, didAdd marker: NSRulerMarker) {
        ruler.invalidateHashMarks()
    }

    open override func rulerView(_ ruler: NSRulerView, didRemove marker: NSRulerMarker) {
        ruler.invalidateHashMarks()
    }

    open override func rulerView(_ ruler: NSRulerView, locationFor point: NSPoint) -> CGFloat {
        if let textLayoutFragment = textLayoutManager.textLayoutFragment(for: point) {
            var baselineOffset: CGFloat = 0
            if let paragraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                baselineOffset = -(typingLineHeight * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
            }

            let effectiveFrame = textLayoutFragment.layoutFragmentFrame.moved(dy: baselineOffset)
            return effectiveFrame.maxY
        }

        return point.y
    }

    open override func rulerView(_ ruler: NSRulerView, handleMouseDownWith event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let textLayoutFragment = textLayoutManager.textLayoutFragment(for: point),
              let textSegmentFrame = textLayoutManager.textSegmentFrame(at: textLayoutFragment.rangeInElement.location, type: .highlight)?.pixelAligned
        else {
            return
        }

        let relativePoint = convert(NSZeroPoint, from: self)
        let selectionFrame = textSegmentFrame.pixelAligned

        let markerLocation = (ruler.markers ?? []).filter { marker in
            selectionFrame.maxY.isAlmostEqual(to: marker.markerLocation)
        }

        if markerLocation.isEmpty {
            let marker = STRulerMarker(rulerView: ruler, markerLocation: selectionFrame.maxY + relativePoint.y, height: selectionFrame.height)
            marker.isMovable = true
            marker.isRemovable = true

            // For unknown reason an NSRulerView automatically increases the reservedThicknessForMarkers to 2.0
            // Adds 2px in the marker.imageRectInRuler to the left in
            ruler.clientView?.rulerView(ruler, willAdd: marker, atLocation: marker.markerLocation)
            ruler.addMarker(marker)
            ruler.clientView?.rulerView(ruler, didAdd: marker)

            // track not supported until solve tracking visual glithes
            // ruler.trackMarker(marker, withMouseEvent: event)
        } else {
            markerLocation.forEach { marker in
                ruler.removeMarker(marker)
                ruler.clientView?.rulerView(ruler, didRemove: marker)
            }
        }
        ruler.needsDisplay = true
    }
}
