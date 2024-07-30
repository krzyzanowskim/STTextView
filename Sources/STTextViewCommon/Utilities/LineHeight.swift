//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

package func calculateDefaultLineHeight(for font: CTFont) -> CGFloat {
    /// Heavily inspired by WebKit

    let kLineHeightAdjustment: CGFloat = 0.15

    var ascent = CTFontGetAscent(font)
    var descent = CTFontGetDescent(font)
    var lineGap = CTFontGetLeading(font)

    let familyName = CTFontCopyFamilyName(font) as String

    if shouldUseAdjustment(familyName) {
        // Needs ascent adjustment
        ascent += round((ascent + descent) * kLineHeightAdjustment);
    }

    // Compute line spacing before the line metrics hacks are applied.
    var lineSpacing = round(ascent) + round(descent) + round(lineGap);

    // Hack Hiragino line metrics to allow room for marked text underlines.
    if descent < 3, lineGap >= 3, familyName.hasPrefix("Hiragino") == true {
        lineGap -= 3 - descent
        descent = 3
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    let adjustment = shouldUseAdjustment(familyName) ? ceil(ascent + descent) * kLineHeightAdjustment : 0
    lineGap = ceil(lineGap)
    lineSpacing = ceil(ascent) + adjustment + ceil(descent) + lineGap
    ascent = ceil((ascent + adjustment))
    descent = ceil(descent)
#endif

    return lineSpacing
}

private func shouldUseAdjustment(_ familyName: String) -> Bool {
    familyName.caseInsensitiveCompare("Times") == .orderedSame
        || familyName.caseInsensitiveCompare("Helvetica") == .orderedSame
        || familyName.caseInsensitiveCompare("Courier") == .orderedSame // macOS only
        || familyName.caseInsensitiveCompare(".Helvetica NeueUI") == .orderedSame
}
