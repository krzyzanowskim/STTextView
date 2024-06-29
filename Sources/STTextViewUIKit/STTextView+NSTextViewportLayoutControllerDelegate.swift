//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        bounds
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        // TODO: update difference, not all layers
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let fragmentView = fragmentViewMap.object(forKey: textLayoutFragment) ?? STTextLayoutFragmentView(layoutFragment: textLayoutFragment, frame: textLayoutFragment.layoutFragmentFrame)
        // Adjust position
        let oldFrame = fragmentView.frame
        fragmentView.frame = textLayoutFragment.layoutFragmentFrame//.pixelAligned
        if !oldFrame.isAlmostEqual(to: fragmentView.frame)  {
            fragmentView.setNeedsLayout()
            fragmentView.setNeedsDisplay()
        }

        contentView.addSubview(fragmentView)
        fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        contentSize = textLayoutManager.usageBoundsForTextContainer.size
        sizeToFit()
        // adjustViewportOffsetIfNeeded()

        // if let viewportRange = textViewportLayoutController.viewportRange {
        //    for events in plugins.events {
        //        events.didLayoutViewportHandler?(viewportRange)
        //    }
        // }
    }
}
