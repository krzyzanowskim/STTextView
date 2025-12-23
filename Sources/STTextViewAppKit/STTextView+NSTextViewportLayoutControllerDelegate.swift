//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        lastUsedFragmentViews = Set(fragmentViewMap.objectEnumerator()?.allObjects as? [STTextLayoutFragmentView] ?? [])

        if ProcessInfo().environment["ST_LAYOUT_DEBUG"] == "YES" {
            let viewportDebugView = NSView(frame: viewportBounds(for: textViewportLayoutController))
            viewportDebugView.clipsToBounds = true
            viewportDebugView.wantsLayer = true
            viewportDebugView.layer?.borderColor = NSColor.magenta.cgColor
            viewportDebugView.layer?.borderWidth = 4
            contentViewportView.addSubview(viewportDebugView)
        }
    }

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        let gutterWidth = gutterView?.frame.width ?? 0
        let prepared = preparedContentRect.insetBy(dx: gutterWidth, dy: 0)
        var visible = contentView.visibleRect

        // Clamp negative origins to 0 (handles overscroll bounce)
        if visible.minX < 0 {
            visible.size.width += visible.minX
            visible.origin.x = 0
        }
        if visible.minY < 0 {
            visible.size.height += visible.minY
            visible.origin.y = 0
        }

        if prepared.intersects(visible) {
            return prepared.union(visible)
        } else {
            return visible
        }
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
        }
        lastUsedFragmentViews.removeAll()

        updateContentSizeIfNeeded()

        // When scrolled to the end of the document, relocate viewport to ensure proper layout
        if let scrollView, let documentView = scrollView.documentView, scrollView.contentView.bounds.maxY >= documentView.bounds.maxY,
           let viewportRange = textViewportLayoutController.viewportRange,
           let textRange = NSTextRange(location: viewportRange.endLocation, end: textLayoutManager.documentRange.endLocation), !textRange.isEmpty {
            logger.debug("Relocate viewport to the bottom")
            relocateViewport(to: textLayoutManager.documentRange.endLocation)
        }

        updateSelectedRangeHighlight()
        updateSelectedLineHighlight()
        layoutGutter()

        if let viewportRange = textViewportLayoutController.viewportRange {
            for events in plugins.events {
                events.didLayoutViewportHandler?(viewportRange)
            }
        }
    }
}
