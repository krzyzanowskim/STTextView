//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        lastUsedFragmentViews = Set(fragmentViewMap.objectEnumerator()?.allObjects as? [STTextLayoutFragmentView] ?? [])

        if ProcessInfo().environment["ST_LAYOUT_DEBUG"] == "YES" {
            contentViewportView.subviews.removeAll { view in
                view is ViewportDebugView
            }
            let viewportDebugView = ViewportDebugView(frame: viewportBounds(for: textViewportLayoutController))
            viewportDebugView.clipsToBounds = true
            viewportDebugView.wantsLayer = true
            viewportDebugView.layer?.borderColor = NSColor.magenta.cgColor
            viewportDebugView.layer?.borderWidth = 4
            contentViewportView.addSubview(viewportDebugView)
        }
    }

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        var viewportBounds = visibleContentBounds()

        // Keep a prefetch band around the visible area so small scrolls can
        // reuse the current TextKit viewport.
        let verticalPrefetch = viewportBounds.height * 0.5
        let upwardPrefetch = min(verticalPrefetch, viewportBounds.minY)
        viewportBounds.origin.y -= upwardPrefetch
        viewportBounds.size.height += upwardPrefetch + verticalPrefetch

        viewportBounds.origin.x = 0
        viewportBounds.size.width = contentView.bounds.width
        return viewportBounds
    }

    func visibleContentBounds() -> CGRect {
        var viewportBounds = contentView.visibleRect

        // Clamp negative origins to 0 (handles overscroll bounce)
        if viewportBounds.minX < 0 {
            viewportBounds.size.width = max(0, viewportBounds.width + viewportBounds.minX)
            viewportBounds.origin.x = 0
        }
        if viewportBounds.minY < 0 {
            viewportBounds.size.height = max(0, viewportBounds.height + viewportBounds.minY)
            viewportBounds.origin.y = 0
        }

        return viewportBounds
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        var needsDisplay = false
        if let textLayoutFragment = textLayoutFragment as? STTextLayoutFragment,
           textLayoutFragment.showsInvisibleCharacters != showsInvisibleCharacters {
            textLayoutFragment.showsInvisibleCharacters = showsInvisibleCharacters
            needsDisplay = true
        }

        // textLayoutFragment.layoutFragmentFrame is calculated in `self` coordinates,
        // but we use it in contentViewportView coordinates. contentViewportView frame is offset by gutterWidth
        let layoutFragmentFrame = textLayoutFragment.layoutFragmentFrame
        let fragmentView: STTextLayoutFragmentView
        if let cachedFragmentView = fragmentViewMap.object(forKey: textLayoutFragment) {
            cachedFragmentView.layoutFragment = textLayoutFragment
            fragmentView = cachedFragmentView
            lastUsedFragmentViews.remove(cachedFragmentView)
        } else {
            fragmentView = STTextLayoutFragmentView(layoutFragment: textLayoutFragment, frame: layoutFragmentFrame.pixelAligned)
            fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
        }

        // Adjust fragment view frame
        if !fragmentView.frame.isAlmostEqual(to: layoutFragmentFrame.pixelAligned) {
            fragmentView.frame = textLayoutFragment.layoutFragmentFrame.pixelAligned
            fragmentView.needsLayout = true
            needsDisplay = true
        }

        if needsDisplay {
            fragmentView.needsDisplay = true
        }

        if fragmentView.superview != contentViewportView {
            contentViewportView.addSubview(fragmentView)
        }
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        for staleView in lastUsedFragmentViews {
            staleView.removeFromSuperview()
            fragmentViewMap.removeObject(forKey: staleView.layoutFragment)
        }
        lastUsedFragmentViews.removeAll(keepingCapacity: true)

        updateSelectedRangeHighlight()
        updateSelectedLineHighlight()
        layoutGutter()
        recordDidLayoutViewport(textViewportLayoutController.viewportRange)
    }
}

private class ViewportDebugView: NSView { }
