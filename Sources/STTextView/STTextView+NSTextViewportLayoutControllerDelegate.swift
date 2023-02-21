//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        // viewportBounds affects layout. layoutFragments from outside of the viewport bounds are broken.
        // It's visible in line number ruler. Until I figure correct calculation of bounds
        // the viewport is effectively whole textview = no viewport.
        // Maybe overdraw is too small, maybe something else.
        //
        // Return bounds until resolve bounds problem
        // return bounds

        let overdrawRect = preparedContentRect
        var minY: CGFloat = 0
        var maxY: CGFloat = 0

        if overdrawRect.intersects(visibleRect) {
            // Use preparedContentRect for vertical overdraw and ensure visibleRect is included at the minimum,
            // the width is always bounds width for proper line wrapping.
            minY = min(overdrawRect.minY, max(visibleRect.minY, bounds.minY))
            maxY = max(overdrawRect.maxY, visibleRect.maxY)
        } else {
            // We use visible rect directly if preparedContentRect does not intersect.
            // This can happen if overdraw has not caught up with scrolling yet, such as before the first layout.
            minY = visibleRect.minY
            maxY = visibleRect.maxY
        }
        return CGRect(x: bounds.minX, y: minY, width: bounds.width, height: maxY - minY)
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        // TODO: update difference, not all layers
        contentLayer.sublayers = nil
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        updateFrameSizeIfNeeded()
        updateSelectionHighlights()
        adjustViewportOffsetIfNeeded()
        scrollView?.verticalRulerView?.invalidateHashMarks()
        scrollView?.verticalRulerView?.needsDisplay = true
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let fragmentLayer = fragmentLayerMap.object(forKey: textLayoutFragment) as? STTextLayoutFragmentLayer ?? STTextLayoutFragmentLayer(layoutFragment: textLayoutFragment)
        fragmentLayer.contentsScale = backingScaleFactor

        // Adjust position
        let oldFrame = fragmentLayer.frame
        fragmentLayer.frame = textLayoutFragment.layoutFragmentFrame.pixelAligned
        if oldFrame != fragmentLayer.frame {
            fragmentLayer.needsLayout()
            fragmentLayer.needsDisplay()
        }

        contentLayer.addSublayer(fragmentLayer)
        fragmentLayerMap.setObject(fragmentLayer, forKey: textLayoutFragment)
    }

    internal func adjustViewportOffsetIfNeeded() {
        guard let scrollView = scrollView else { return }
        let clipView = scrollView.contentView

        func adjustViewportOffset() {
            let viewportLayoutController = textLayoutManager.textViewportLayoutController
            var layoutYPoint: CGFloat = 0
            textLayoutManager.enumerateTextLayoutFragments(from: viewportLayoutController.viewportRange!.location, options: [.reverse, .ensuresLayout]) { layoutFragment in
                layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
                return true //return false?
            }

            if !layoutYPoint.isZero {
                let adjustmentDelta = bounds.minY - layoutYPoint
                viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
                scroll(CGPoint(x: clipView.bounds.minX, y: clipView.bounds.minY + adjustmentDelta))
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }

        let viewportLayoutController = textLayoutManager.textViewportLayoutController
        let contentOffset = clipView.bounds.minY
        if contentOffset < clipView.bounds.height, let viewportRange = viewportLayoutController.viewportRange,
            viewportRange.location > textLayoutManager.documentRange.location
        {
            // Nearing top, see if we need to adjust and make room above.
            adjustViewportOffset()
        } else if let viewportRange = viewportLayoutController.viewportRange, viewportRange.location == textLayoutManager.documentRange.location {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }
}
