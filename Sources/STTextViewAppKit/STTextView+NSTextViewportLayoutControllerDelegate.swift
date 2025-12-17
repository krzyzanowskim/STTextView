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
            viewportDebugView.clipsToBounds = true
            viewportDebugView.wantsLayer = true
            viewportDebugView.layer?.borderColor = NSColor.magenta.cgColor
            viewportDebugView.layer?.borderWidth = 4
            contentViewportView.addSubview(viewportDebugView)
        }
    }

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        contentView.visibleRect.union(preparedContentRect.insetBy(dx: gutterView?.frame.width ?? 0, dy: 0))
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
        // Handle content beyond viewport - ensure layout, resize frame, and create fragment views.
        // relocateViewport() triggers configureRenderingSurfaceFor to create views for laid-out content.
        // adjustViewport() is only called when bottomPadding == 0 to avoid scroll position fighting.
        if let scrollView, let documentView = scrollView.documentView,
           scrollView.contentView.bounds.maxY >= documentView.bounds.maxY,
           let viewportRange = textViewportLayoutController.viewportRange,
           let textRange = NSTextRange(location: viewportRange.endLocation, end: textLayoutManager.documentRange.endLocation),
           !textRange.isEmpty
        {
            logger.debug("Ensure layout for content beyond viewport")
            textLayoutManager.ensureLayout(for: textRange)
            var lastLineMaxY = textViewportLayoutController.viewportBounds.maxY
            textLayoutManager.enumerateTextLayoutFragments(from: textRange.endLocation, options: [.reverse, .ensuresLayout]) { layoutFragment in
                lastLineMaxY = layoutFragment.layoutFragmentFrame.maxY
                return false
            }

            // Set frame height (include bottomPadding if set)
            let newHeight = lastLineMaxY + bottomPadding
            setFrameSize(CGSize(width: frame.width, height: newHeight))

            // Relocate viewport to trigger fragment view creation
            let suggestedAnchor = textViewportLayoutController.relocateViewport(to: textRange.endLocation)

            // Only adjust viewport when NO padding - adjustment fights with padding
            if bottomPadding == 0 {
                let offset = frame.height - suggestedAnchor
                if !offset.isAlmostZero() {
                    logger.debug("  Adjust viewport to anchor: \(suggestedAnchor)")
                    textViewportLayoutController.adjustViewport(byVerticalOffset: -offset)
                }
            }
        } else if textViewportLayoutController.viewportRange == nil {
            // Recovery branch for when viewportRange is nil - restore from cached fragments
            logger.debug("Attempt to recover last viewportRange from cache")

            let lastLayoutFragment = (fragmentViewMap.keyEnumerator().allObjects as! [NSTextLayoutFragment]).max { lhs, rhs in
                lhs.layoutFragmentFrame.maxY < rhs.layoutFragmentFrame.maxY
            }

            guard let lastLayoutFragment else {
                logger.debug("  failed to find last fragment from cache.")
                return
            }

            let textRange = NSTextRange(location: lastLayoutFragment.rangeInElement.endLocation, end: textLayoutManager.documentRange.endLocation)!
            textLayoutManager.ensureLayout(for: textRange)
            var lastLineMaxY = textViewportLayoutController.viewportBounds.maxY
            textLayoutManager.enumerateTextLayoutFragments(from: textRange.endLocation, options: [.reverse, .ensuresLayout]) { layoutFragment in
                lastLineMaxY = layoutFragment.layoutFragmentFrame.maxY
                return false
            }

            let newHeight = lastLineMaxY + bottomPadding
            setFrameSize(CGSize(width: frame.width, height: newHeight))

            let suggestedAnchor = textViewportLayoutController.relocateViewport(to: textRange.endLocation)

            if bottomPadding == 0 {
                let offset = frame.height - suggestedAnchor
                if !offset.isAlmostZero() {
                    logger.debug("  Adjust viewport to anchor: \(suggestedAnchor)")
                    textViewportLayoutController.adjustViewport(byVerticalOffset: -offset)
                }
            }
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
