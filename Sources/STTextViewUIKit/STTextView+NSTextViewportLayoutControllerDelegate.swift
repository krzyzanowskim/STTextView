//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        var viewportBounds = visibleContentBounds()

        // Keep a prefetch band around the visible area so small scrolls can
        // reuse the current TextKit viewport.
        let verticalPrefetch = viewportBounds.height * 0.5
        let upwardPrefetch = min(verticalPrefetch, max(0, viewportBounds.minY))
        viewportBounds.origin.y -= upwardPrefetch
        viewportBounds.size.height += upwardPrefetch + verticalPrefetch

        viewportBounds.origin.x = 0
        viewportBounds.size.width = max(viewportBounds.width, contentView.bounds.width)
        return viewportBounds
    }

    func visibleContentBounds() -> CGRect {
        let scrollInsets = adjustedContentInset
        return CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y - scrollInsets.top - textContainerInset.top,
            width: bounds.width,
            height: bounds.height + scrollInsets.top + scrollInsets.bottom + textContainerInset.top + textContainerInset.bottom
        )
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        lastUsedFragmentViews = Set(fragmentViewMap.objectEnumerator()?.allObjects as? [STTextLayoutFragmentView] ?? [])
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        var needsDisplay = false
        if let textLayoutFragment = textLayoutFragment as? STTextLayoutFragment,
           textLayoutFragment.showsInvisibleCharacters != showsInvisibleCharacters {
            textLayoutFragment.showsInvisibleCharacters = showsInvisibleCharacters
            needsDisplay = true
        }

        let layoutFragmentFrame = textLayoutFragment.layoutFragmentFrame
        let fragmentView: STTextLayoutFragmentView
        if let cachedFragmentView = fragmentViewMap.object(forKey: textLayoutFragment) {
            fragmentView = cachedFragmentView
            lastUsedFragmentViews.remove(cachedFragmentView)
        } else {
            fragmentView = STTextLayoutFragmentView(layoutFragment: textLayoutFragment, frame: layoutFragmentFrame)
            fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
        }

        // Adjust fragment view frame
        if !fragmentView.frame.isAlmostEqual(to: layoutFragmentFrame) {
            fragmentView.frame = layoutFragmentFrame
            fragmentView.setNeedsLayout()
            needsDisplay = true
        }

        if needsDisplay {
            fragmentView.setNeedsDisplay()
        }

        if fragmentView.superview != contentView {
            contentView.addSubview(fragmentView)
        }
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        for staleView in lastUsedFragmentViews {
            staleView.removeFromSuperview()
            fragmentViewMap.removeObject(forKey: staleView.layoutFragment)
        }
        lastUsedFragmentViews.removeAll()

        if let viewportRange = textViewportLayoutController.viewportRange {
            textLayoutManager.ensureLayout(for: viewportRange)
        }

        updateContentSizeIfNeeded()

        updateSelectedLineHighlight()
        layoutGutter()

        recordDidLayoutViewport(textViewportLayoutController.viewportRange)
    }
}
