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

    /// Get visible fragment views from the map and sort by document order
    /// - Parameters:
    ///   - fragmentViewMap: Map of layout fragments to their rendered views
    ///   - viewportRange: The visible text range in the viewport
    /// - Returns: Array of (layoutFragment, fragmentView) tuples sorted by document position
    package static func visibleFragmentViewsInViewport<FragmentView>(
        fragmentViewMap: NSMapTable<NSTextLayoutFragment, FragmentView>,
        viewportRange: NSTextRange
    ) -> [(NSTextLayoutFragment, FragmentView)] {
        (fragmentViewMap.keyEnumerator().allObjects as! [NSTextLayoutFragment])
            .compactMap { layoutFragment -> (NSTextLayoutFragment, FragmentView)? in
                guard let fragmentView = fragmentViewMap.object(forKey: layoutFragment),
                      layoutFragment.rangeInElement.intersects(viewportRange)
                else {
                    return nil
                }
                return (layoutFragment, fragmentView)
            }
            .sorted { lhs, rhs in
                lhs.0.rangeInElement.location.compare(rhs.0.rangeInElement.location) == .orderedAscending
            }
    }

    /// Calculate positioning metrics for a line number cell
    /// - Parameters:
    ///   - textLineFragment: The text line fragment to calculate metrics for
    ///   - layoutFragment: The layout fragment containing the line
    ///   - fragmentViewFrame: Optional frame of the rendered fragment view (for perfect alignment)
    ///   - contentOffset: Content offset for coordinate adjustment (UIKit scrolling, .zero for AppKit)
    /// - Returns: (baselineYOffset, locationForFirstCharacter, cellFrame)
    package static func calculateLineNumberMetrics(
        for textLineFragment: NSTextLineFragment,
        in layoutFragment: NSTextLayoutFragment,
        fragmentViewFrame: CGRect?,
        contentOffset: CGPoint = .zero
    ) -> (baselineYOffset: CGFloat, locationForFirstCharacter: CGPoint, cellFrame: CGRect) {

        var baselineYOffset: CGFloat = 0
        let locationForFirstCharacter: CGPoint
        let cellFrame: CGRect

        if layoutFragment.isExtraLineFragment {
            // Extra line fragments require special handling due to FB15131180
            // They don't have fragment views and need calculated positioning based on previous line
            locationForFirstCharacter = STGutterCalculations.locationForFirstCharacter(
                in: layoutFragment,
                textLineFragment: textLineFragment,
                isExtraTextLineFragment: textLineFragment.isExtraLineFragment
            )

            if let paragraphStyle = STGutterCalculations.paragraphStyleForBaseline(
                in: layoutFragment,
                textLineFragment: textLineFragment,
                isExtraTextLineFragment: textLineFragment.isExtraLineFragment
            ) {
                let lineHeight = textLineFragment.isExtraLineFragment
                    ? layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2].typographicBounds.height
                    : textLineFragment.typographicBounds.height
                baselineYOffset = STGutterCalculations.calculateBaselineOffset(
                    lineHeight: lineHeight,
                    paragraphStyle: paragraphStyle
                )
            }

            let rawFrame = STGutterCalculations.calculateExtraLineFragmentFrame(
                layoutFragment: layoutFragment,
                textLineFragment: textLineFragment,
                isExtraTextLineFragment: textLineFragment.isExtraLineFragment
            )

            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                cellFrame = rawFrame.pixelAligned
            #else
                cellFrame = CGRect(
                    origin: CGPoint(
                        x: rawFrame.origin.x,
                        y: rawFrame.origin.y - contentOffset.y
                    ),
                    size: rawFrame.size
                )
            #endif

        } else {
            // Normal fragments: use fragment view frame if available, otherwise calculate
            locationForFirstCharacter = textLineFragment.locationForCharacter(at: 0)

            if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                baselineYOffset = STGutterCalculations.calculateBaselineOffset(
                    lineHeight: textLineFragment.typographicBounds.height,
                    paragraphStyle: paragraphStyle
                )
            }

            if let fragmentViewFrame {
                // Use the actual rendered fragment view frame for perfect alignment
                cellFrame = CGRect(
                    origin: CGPoint(
                        x: fragmentViewFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                        y: fragmentViewFrame.origin.y + textLineFragment.typographicBounds.origin.y - contentOffset.y
                    ),
                    size: CGSize(
                        width: fragmentViewFrame.width,
                        height: fragmentViewFrame.height
                    )
                )
            } else {
                // Fallback to layout fragment frame if view not available yet
                #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                    cellFrame = CGRect(
                        origin: CGPoint(
                            x: layoutFragment.layoutFragmentFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                            y: layoutFragment.layoutFragmentFrame.origin.y + textLineFragment.typographicBounds.origin.y
                        ),
                        size: CGSize(
                            width: layoutFragment.layoutFragmentFrame.width,
                            height: layoutFragment.layoutFragmentFrame.height
                        )
                    ).pixelAligned
                #else
                    cellFrame = CGRect(
                        origin: CGPoint(
                            x: layoutFragment.layoutFragmentFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                            y: layoutFragment.layoutFragmentFrame.origin.y + textLineFragment.typographicBounds.origin.y - contentOffset.y
                        ),
                        size: CGSize(
                            width: layoutFragment.layoutFragmentFrame.width,
                            height: layoutFragment.layoutFragmentFrame.height
                        )
                    )
                #endif
            }
        }

        return (baselineYOffset, locationForFirstCharacter, cellFrame)
    }

    /// Calculate baseline Y offset based on paragraph style line height multiple
    // TODO: This only handles lineHeightMultiple, not minimumLineHeight/maximumLineHeight.
    // May need to use stEffectiveLineMetrics for fixed line heights.
    package static func calculateBaselineOffset(
        lineHeight: CGFloat,
        paragraphStyle: NSParagraphStyle
    ) -> CGFloat {
        -(lineHeight * (paragraphStyle.stLineHeightMultiple - 1.0) / 2)
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

    /// Calculate frame for extra line fragment using previous line fragment
    /// Workaround for FB15131180 - invalid frame being reported for extra line fragments
    package static func calculateExtraLineFragmentFrame(
        layoutFragment: NSTextLayoutFragment,
        textLineFragment: NSTextLineFragment,
        isExtraTextLineFragment: Bool
    ) -> CGRect {
        if !isExtraTextLineFragment {
            return CGRect(
                origin: CGPoint(
                    x: layoutFragment.layoutFragmentFrame.origin.x + textLineFragment.typographicBounds.origin.x,
                    y: layoutFragment.layoutFragmentFrame.origin.y + textLineFragment.typographicBounds.origin.y
                ),
                size: CGSize(
                    width: textLineFragment.typographicBounds.width,
                    height: textLineFragment.typographicBounds.height
                )
            )
        } else {
            // Use values from the same layoutFragment but previous line, that is not extra line fragment.
            // Since this is extra line fragment, it is guaranteed that there is at least 2 line fragments in the layout fragment
            let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
            return CGRect(
                origin: CGPoint(
                    x: layoutFragment.layoutFragmentFrame.origin.x + prevTextLineFragment.typographicBounds.origin.x,
                    y: layoutFragment.layoutFragmentFrame.origin.y + prevTextLineFragment.typographicBounds.maxY
                ),
                size: CGSize(
                    width: textLineFragment.typographicBounds.width,
                    height: prevTextLineFragment.typographicBounds.height
                )
            )
        }
    }

    /// Get location for first character, handling extra line fragments
    package static func locationForFirstCharacter(
        in layoutFragment: NSTextLayoutFragment,
        textLineFragment: NSTextLineFragment,
        isExtraTextLineFragment: Bool
    ) -> CGPoint {
        if !isExtraTextLineFragment || !layoutFragment.isExtraLineFragment {
            return textLineFragment.locationForCharacter(at: 0)
        } else {
            // Use previous line fragment for extra line fragments
            let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
            return prevTextLineFragment.locationForCharacter(at: 0)
        }
    }

    /// Get paragraph style for baseline calculations, handling extra line fragments
    package static func paragraphStyleForBaseline(
        in layoutFragment: NSTextLayoutFragment,
        textLineFragment: NSTextLineFragment,
        isExtraTextLineFragment: Bool
    ) -> NSParagraphStyle? {
        if !isExtraTextLineFragment || !layoutFragment.isExtraLineFragment {
            return textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        } else {
            let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
            return prevTextLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        }
    }
}
