//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        let overdrawRect = preparedContentRect
        let minY: CGFloat
        let maxY: CGFloat
        let minX: CGFloat
        let maxX: CGFloat

        let visibleRect = contentView.visibleRect

        if !overdrawRect.isEmpty, overdrawRect.intersects(visibleRect) {
            // Use preparedContentRect for vertical overdraw and ensure visibleRect is included at the minimum,
            // the width is always bounds width for proper line wrapping.
            minX = min(overdrawRect.minX, max(visibleRect.minX, bounds.minX))
            minY = min(overdrawRect.minY, max(visibleRect.minY, bounds.minY))
            maxX = max(overdrawRect.maxX, visibleRect.maxX)
            maxY = max(overdrawRect.maxY, visibleRect.maxY)
        } else {
            // We use visible rect directly if preparedContentRect does not intersect.
            // This can happen if overdraw has not caught up with scrolling yet, such as before the first layout.
            minX = visibleRect.minX
            minY = visibleRect.minY
            maxX = visibleRect.maxX
            maxY = visibleRect.maxY
        }

        let rect = CGRect(x: minX, y: minY, width: maxX, height: maxY - minY)
        return rect
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        // Cleanup viewport view area
        _isLayoutViewport = true
        contentViewportView.subviews = []
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        if let textLayoutFragment = textLayoutFragment as? STTextLayoutFragment,
           textLayoutFragment.showsInvisibleCharacters != showsInvisibleCharacters
        {
            textLayoutFragment.showsInvisibleCharacters = showsInvisibleCharacters
        }

        let fragmentView: STTextLayoutFragmentView
        if let cachedFragmentView = fragmentViewMap.object(forKey: textLayoutFragment) {
            cachedFragmentView.layoutFragment = textLayoutFragment
            fragmentView = cachedFragmentView
        } else {
            let layoutFragmentFrame = contentViewportView.convert(textLayoutFragment.layoutFragmentFrame, from: contentView)
            fragmentView = STTextLayoutFragmentView(layoutFragment: textLayoutFragment, frame: layoutFragmentFrame.pixelAligned)
        }

        // Adjust fragment view frame
        let layoutFragmentFrame = contentViewportView.convert(textLayoutFragment.layoutFragmentFrame, from: contentView)
        if !fragmentView.frame.isAlmostEqual(to: layoutFragmentFrame.pixelAligned)  {
            fragmentView.frame = layoutFragmentFrame.pixelAligned
            fragmentView.needsLayout = true
            fragmentView.needsDisplay = true
        }

        contentViewportView.addSubview(fragmentView)
        fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        sizeToFit()
        updateContentViewportView(textViewportLayoutController)
        updateSelectedRangeHighlight()
        updateSelectedLineHighlight()
        adjustViewportOffsetIfNeeded()
        layoutGutter()

        if let viewportRange = textViewportLayoutController.viewportRange {
            for events in plugins.events {
                events.didLayoutViewportHandler?(viewportRange)
            }
        }

        _isLayoutViewport = false
    }

    private func updateContentViewportView(_ textViewportLayoutController: NSTextViewportLayoutController) {
        var f = textViewportLayoutController.viewportBounds
        f.origin.x = contentView.frame.origin.x
        f.size.width = contentView.frame.size.width
        contentViewportView.frame = f
    }

    private func adjustViewportOffsetIfNeeded() {
        guard let clipView = scrollView?.contentView else {
            return
        }

        func adjustViewportOffset() {
            guard let viewportRange = viewportLayoutController.viewportRange else {
                return
            }

            let viewportLayoutController = textLayoutManager.textViewportLayoutController
            var layoutYPoint: CGFloat = 0
            textLayoutManager.enumerateTextLayoutFragments(from: viewportRange.location, options: [.reverse, .ensuresLayout]) { layoutFragment in
                layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
                return true // NOTE: should break early (return false)?
            }

            if !layoutYPoint.isZero {
                let adjustmentDelta = bounds.minY - layoutYPoint
                viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
                scroll(CGPoint(x: clipView.bounds.minX, y: clipView.bounds.minY + adjustmentDelta))
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
