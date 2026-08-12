//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
#if canImport(UIKit)
    import UIKit
#endif

package extension NSTextLayoutManager {

    /// The size the laid out text occupies, measured from the text container origin.
    ///
    /// `usageBoundsForTextContainer` is offset by the leading line fragment padding, so the
    /// trailing edge of the longest line is at `maxX`, not at `size.width`. The same padding
    /// is added on the trailing side, keeping the longest line off the edge of the scrollable
    /// area and mirroring the leading padding.
    ///
    /// The value is an estimate: TextKit refines `usageBoundsForTextContainer` as more of the
    /// document is laid out.
    func textContentExtent() -> CGSize {
        let usageBounds = usageBoundsForTextContainer
        let trailingPadding = textContainer?.lineFragmentPadding ?? 0
        return CGSize(
            width: usageBounds.maxX + trailingPadding,
            height: usageBounds.maxY
        )
    }
}
