//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

package extension NSTextLineFragment {

    /// The paragraph style applied to this line fragment, or `.default` if none.
    ///
    /// Extracts the paragraph style from the first character of the line fragment's
    /// attributed string. This is the common pattern used throughout STTextView for
    /// determining line height, spacing, and other paragraph-level attributes.
    var stParagraphStyle: NSParagraphStyle {
        attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle ?? .default
    }

    /// Returns the effective line height for this fragment based on its paragraph style.
    ///
    /// Convenience method that combines `stParagraphStyle` and `stEffectiveLineHeight`,
    /// using this fragment's `typographicBounds.height` as the base height.
    var stEffectiveLineHeight: CGFloat {
        stParagraphStyle.stEffectiveLineHeight(baseHeight: typographicBounds.height)
    }

    /// Returns the effective line metrics (height and y-offset) for this fragment.
    ///
    /// Convenience method that combines `stParagraphStyle` and `stEffectiveLineMetrics`,
    /// using this fragment's `typographicBounds.height` as the base height.
    var stEffectiveLineMetrics: (height: CGFloat, yOffset: CGFloat) {
        stParagraphStyle.stEffectiveLineMetrics(baseHeight: typographicBounds.height)
    }
}
