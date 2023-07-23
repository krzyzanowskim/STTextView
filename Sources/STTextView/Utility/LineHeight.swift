//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa


internal func defaultLineHeight(for font: NSFont) -> CGFloat {
    /// Heavily inspired by WebKit

    let kLineHeightAdjustment: CGFloat = 0.15

    var ascent = CTFontGetAscent(font)
    var descent = CTFontGetDescent(font)
    var lineGap = CTFontGetLeading(font)

    if shouldUseAdjustment(font) {
        // Needs ascent adjustment
        ascent += round((ascent + descent) * kLineHeightAdjustment);
    }

    // Compute line spacing before the line metrics hacks are applied.
    let lineSpacing = round(ascent) + round(descent) + round(lineGap);

    // Hack Hiragino line metrics to allow room for marked text underlines.
    if descent < 3, lineGap >= 3, font.familyName?.hasPrefix("Hiragino") == true {
        lineGap -= 3 - descent
        descent = 3
    }

#if os(iOS)
    let adjustment = shouldUseAdjustment(font) ? ceil(ascent + descent) * kLineHeightAdjustment : 0
    lineGap = ceil(lineGap)
    lineSpacing = ceil(ascent) + adjustment + ceil(descent) + lineGap
    ascent = ceil((ascent + adjustment))
    descent = ceil(descent)
#endif

    return lineSpacing
}

private func shouldUseAdjustment(_ font: NSFont) -> Bool {
    guard let familyName = font.familyName else {
        return false
    }

    return familyName.caseInsensitiveCompare("Times") == .orderedSame
    || familyName.caseInsensitiveCompare("Helvetica") == .orderedSame
    || familyName.caseInsensitiveCompare("Courier") == .orderedSame // macOS only
    || familyName.caseInsensitiveCompare(".Helvetica NeueUI") == .orderedSame
}
