//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

import Foundation
import STTextKitPlus

package enum STGutterCalculations {

    /// Get visible layout fragments with live rendered views, sorted by document order.
    /// - Parameters:
    ///   - fragmentViewMap: Map of layout fragments to their rendered views
    ///   - viewportRange: The visible text range in the viewport
    /// - Returns: Layout fragments sorted by document position
    package static func visibleLayoutFragmentsInViewport(
        fragmentViewMap: NSMapTable<NSTextLayoutFragment, some AnyObject>,
        viewportRange: NSTextRange
    ) -> [NSTextLayoutFragment] {
        fragmentViewMap.keyEnumerator().allObjects
            .compactMap { object -> NSTextLayoutFragment? in
                guard let layoutFragment = object as? NSTextLayoutFragment,
                      fragmentViewMap.object(forKey: layoutFragment) != nil,
                      layoutFragment.rangeInElement.intersects(viewportRange)
                else {
                    return nil
                }
                return layoutFragment
            }
            .sorted { lhs, rhs in
                lhs.rangeInElement.location.compare(rhs.rangeInElement.location) == .orderedAscending
            }
    }

    /// Calculate the frame of a text line fragment in the text layout coordinate space.
    /// - Parameters:
    ///   - textLineFragment: The text line fragment to calculate the frame for.
    ///   - layoutFragment: The layout fragment containing the text line fragment.
    /// - Returns: The unaligned frame. Pixel alignment belongs at the rendering edge.
    package static func textLineFragmentFrame(
        for textLineFragment: NSTextLineFragment,
        in layoutFragment: NSTextLayoutFragment
    ) -> CGRect {
        CGRect(
            origin: CGPoint(
                x: layoutFragment.layoutFragmentFrame.minX + textLineFragment.typographicBounds.minX,
                y: layoutFragment.layoutFragmentFrame.minY + textLineFragment.typographicBounds.minY
            ),
            size: textLineFragment.typographicBounds.size
        )
    }

    /// Calculate the frame represented by a line number cell.
    ///
    /// A regular line number represents the complete logical line, including every wrapped
    /// text line fragment. An extra line fragment continues to use its own independent frame.
    package static func lineNumberFrame(
        for textLineFragment: NSTextLineFragment,
        in layoutFragment: NSTextLayoutFragment
    ) -> CGRect {
        let representedFragments = textLineFragment.isExtraLineFragment
            ? [textLineFragment]
            : layoutFragment.textLineFragments.filter { !$0.isExtraLineFragment }

        return representedFragments.dropFirst().reduce(
            textLineFragmentFrame(
                for: representedFragments.first ?? textLineFragment,
                in: layoutFragment
            )
        ) { frame, fragment in
            frame.union(
                textLineFragmentFrame(
                    for: fragment,
                    in: layoutFragment
                )
            )
        }
    }

    /// Determine if a line is selected based on text layout manager selections
    package static func isLineSelected(
        textLineFragment: NSTextLineFragment,
        layoutFragment: NSTextLayoutFragment,
        contentRangeInElement: NSTextRange,
        textLayoutManager: NSTextLayoutManager
    ) -> Bool {
        textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
            var result = true
            if textLineFragment.isExtraLineFragment {
                let c1 = layoutFragment.rangeInElement.endLocation == selectionTextRange.location
                result = result && c1
            } else {
                let c1 = contentRangeInElement.contains(selectionTextRange)
                let c2 = contentRangeInElement.intersects(selectionTextRange)
                let c3 = selectionTextRange.contains(contentRangeInElement)
                let c4 = selectionTextRange.intersects(contentRangeInElement)
                let c5 = contentRangeInElement.endLocation == selectionTextRange.location
                result = result && (c1 || c2 || c3 || c4 || c5)
            }
            return partialResult && result
        }
    }

}
