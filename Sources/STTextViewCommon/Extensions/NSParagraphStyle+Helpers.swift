//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

package extension NSParagraphStyle {

    /// Normalized value for default paragraph style
    /// NSParagraphStyle.lineHeightMultiple means "default" multiple, that is 1.0
    var stLineHeightMultiple: CGFloat {
        if lineHeightMultiple.isAlmostZero() {
            return 1.0
        } else {
            return lineHeightMultiple
        }
    }

    /// Calculates the effective line height and vertical offset for cursor and line highlight sizing.
    ///
    /// When `minimumLineHeight` equals `maximumLineHeight` (fixed line height), that value
    /// is used to ensure consistent cursor/highlight height across all lines - including
    /// empty lines which would otherwise have different typographic bounds. The y-offset
    /// aligns to the bottom of the original typographic bounds, which matches how TextKit
    /// positions text baselines.
    ///
    /// Otherwise, applies `stLineHeightMultiple` to the base height with centered alignment.
    ///
    /// - Parameter baseHeight: The typographic bounds height from the text line fragment
    /// - Returns: A tuple of (height, yOffset) where yOffset should be added to the origin.y
    func stEffectiveLineMetrics(baseHeight: CGFloat) -> (height: CGFloat, yOffset: CGFloat) {
        // If fixed line height is set (min == max and non-zero), use that
        // This ensures empty lines and content lines have identical cursor/highlight height
        if minimumLineHeight > 0 && minimumLineHeight == maximumLineHeight {
            // Align to the bottom of the line by using the full height difference
            // This ensures empty lines (with larger natural bounds) align with content lines
            let yOffset = baseHeight - minimumLineHeight
            return (minimumLineHeight, yOffset)
        }

        // Otherwise apply lineHeightMultiple (centered)
        let scaledHeight = baseHeight * stLineHeightMultiple
        let yOffset = (baseHeight - scaledHeight) / 2
        return (scaledHeight, yOffset)
    }

    /// Calculates the effective line height for cursor and line highlight sizing.
    ///
    /// When `minimumLineHeight` equals `maximumLineHeight` (fixed line height), that value
    /// is used to ensure consistent cursor/highlight height across all lines - including
    /// empty lines which would otherwise have different typographic bounds.
    ///
    /// Otherwise, applies `stLineHeightMultiple` to the base height.
    ///
    /// - Parameter baseHeight: The typographic bounds height from the text line fragment
    /// - Returns: The effective line height to use for sizing
    func stEffectiveLineHeight(baseHeight: CGFloat) -> CGFloat {
        stEffectiveLineMetrics(baseHeight: baseHeight).height
    }
}
