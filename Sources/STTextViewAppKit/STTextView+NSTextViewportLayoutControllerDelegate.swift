//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        contentViewportView.subviews = []

        // When bottomPadding is set, ensure full document layout BEFORE sizeToFit()
        // so the frame calculation includes all content height.
        if bottomPadding > 0 {
            textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
        }

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
        // Skip viewport relocation when bottomPadding is set.
        // The padding extends the frame beyond content, so relocation would fight with it.
        // Note: ensureLayout is called in willLayout before sizeToFit().
        if bottomPadding > 0 {
            // No-op: layout was ensured in willLayout
        } else if let scrollView, let documentView = scrollView.documentView,
                  scrollView.contentView.bounds.maxY >= documentView.bounds.maxY,
                  let viewportRange = textViewportLayoutController.viewportRange,
                  let textRange = NSTextRange(location: viewportRange.endLocation, end: textLayoutManager.documentRange.endLocation), !textRange.isEmpty
        {
            logger.debug("Attempt to relocate viewport to the bottom")
            textLayoutManager.ensureLayout(for: textRange)
            var lastLineMaxY = textViewportLayoutController.viewportBounds.maxY
            textLayoutManager.enumerateTextLayoutFragments(from: textRange.endLocation, options: [.reverse, .ensuresLayout]) { layoutFragment in
                lastLineMaxY = layoutFragment.layoutFragmentFrame.maxY
                return false // stop.
            }

            setFrameSize(CGSize(width: frame.width, height: lastLineMaxY))

            let suggestedAnchor = textViewportLayoutController.relocateViewport(to: textRange.endLocation)
            let offset = frame.height - suggestedAnchor
            if !offset.isAlmostZero() {
                logger.debug("  Adjust viewport to anchor: \(suggestedAnchor)")
                textViewportLayoutController.adjustViewport(byVerticalOffset: -offset)
            }
        } else if textViewportLayoutController.viewportRange == nil {
            logger.debug("Attempt to recovery last viewportRange from cache")

            // Restore last layout fragment from cached fragments
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
                return false // stop.
            }

            setFrameSize(CGSize(width: frame.width, height: lastLineMaxY))

            let suggestedAnchor = textViewportLayoutController.relocateViewport(to: textRange.endLocation)
            let offset = frame.height - suggestedAnchor
            if !offset.isAlmostZero() {
                logger.debug("  Adjust viewport to anchor: \(suggestedAnchor)")
                textViewportLayoutController.adjustViewport(byVerticalOffset: -offset)
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
