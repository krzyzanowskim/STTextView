//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        // Expand viewport bounds to include fragments slightly outside the visible area
        // for smooth scrolling. Account for both adjustedContentInset and textContainerInset
        // to ensure proper coverage of the text content area.
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
        }
        lastUsedFragmentViews.removeAll()
        // Avoid updating content size during bounce animation as it resets contentSize
        // which cancels the bounce per openradar.appspot.com/8045239
        let isBouncing = (contentOffset.y < -contentInset.top || contentOffset.y > max(0, contentSize.height - bounds.height + contentInset.bottom))
            && (isTracking || isDecelerating)

        if !isBouncing {
            updateContentSizeIfNeeded()
        }

        updateSelectedLineHighlight()
        layoutGutter()

        if let viewportRange = textViewportLayoutController.viewportRange {
            for events in plugins.events {
                events.didLayoutViewportHandler?(viewportRange)
            }
        }
    }
}
