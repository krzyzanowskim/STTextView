//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        contentViewportView.subviews = []
        sizeToFit()

        if ProcessInfo().environment["ST_LAYOUT_DEBUG"] == "YES" {
            let viewportDebugView = NSView(frame: viewportBounds(for: textViewportLayoutController))
            viewportDebugView.frame.origin.x = -(gutterView?.frame.width ?? 0)
            viewportDebugView.clipsToBounds = true
            viewportDebugView.wantsLayer = true
            viewportDebugView.layer?.borderColor = NSColor.magenta.cgColor
            viewportDebugView.layer?.borderWidth = 4
            contentViewportView.addSubview(viewportDebugView)
        }
    }

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        visibleRect.union(preparedContentRect)
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        if let textLayoutFragment = textLayoutFragment as? STTextLayoutFragment,
           textLayoutFragment.showsInvisibleCharacters != showsInvisibleCharacters
        {
            textLayoutFragment.showsInvisibleCharacters = showsInvisibleCharacters
        }

        // textLayoutFragment.layoutFragmentFrame is calculated in `self` coordinates,
        // but we use it in contentViewportView coordinates. contentViewportView frame is offset by gutterWidth
        let layoutFragmentFrame = textLayoutFragment.layoutFragmentFrame
        let fragmentView: STTextLayoutFragmentView
        if let cachedFragmentView = fragmentViewMap.object(forKey: textLayoutFragment) {
            cachedFragmentView.layoutFragment = textLayoutFragment
            fragmentView = cachedFragmentView
        } else {
            fragmentView = STTextLayoutFragmentView(layoutFragment: textLayoutFragment, frame: layoutFragmentFrame.pixelAligned)
        }

        // Adjust fragment view frame
        if !fragmentView.frame.isAlmostEqual(to: layoutFragmentFrame.pixelAligned)  {
            fragmentView.frame = textLayoutFragment.layoutFragmentFrame.pixelAligned
            fragmentView.needsLayout = true
            fragmentView.needsDisplay = true
        }

        contentViewportView.addSubview(fragmentView)
        fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        updateSelectedRangeHighlight()
        updateSelectedLineHighlight()
        adjustViewportOffsetIfNeeded()
        layoutGutter()

        if let viewportRange = textViewportLayoutController.viewportRange {
            for events in plugins.events {
                events.didLayoutViewportHandler?(viewportRange)
            }
        }
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
