//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextKitPlus

extension STTextView: NSTextViewportLayoutControllerDelegate {

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        bounds.inset(dy: -64)
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        // TODO: update difference, not all layers
        for subview in contentView.subviews.filter({ $0 is STTextLayoutFragmentView }) {
            subview.removeFromSuperview()
        }
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let fragmentView = fragmentViewMap.object(forKey: textLayoutFragment) ?? STTextLayoutFragmentView(layoutFragment: textLayoutFragment, frame: textLayoutFragment.layoutFragmentFrame)
        // Adjust position
        if !fragmentView.frame.isAlmostEqual(to: textLayoutFragment.layoutFragmentFrame)  {
            fragmentView.frame = textLayoutFragment.layoutFragmentFrame
            fragmentView.setNeedsLayout()
            fragmentView.setNeedsDisplay()
        }

        if let textLayoutFragment = textLayoutFragment as? STTextLayoutFragment {
            textLayoutFragment.showsInvisibleCharacters = showsInvisibleCharacters
            fragmentView.setNeedsDisplay()
        }

        contentView.addSubview(fragmentView)
        fragmentViewMap.setObject(fragmentView, forKey: textLayoutFragment)
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        sizeToFit()
        // adjustViewportOffsetIfNeeded()

        if let viewportRange = textViewportLayoutController.viewportRange {
           for events in plugins.events {
               events.didLayoutViewportHandler?(viewportRange)
           }
        }
    }
}
