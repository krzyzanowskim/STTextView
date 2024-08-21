//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView: NSTextLayoutManagerDelegate {

    public func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
        let textLayoutFragment = STTextLayoutFragment(
            textElement: textElement,
            range: textElement.elementRange,
            paragraphStyle: _defaultTypingAttributes[.paragraphStyle] as? NSParagraphStyle ?? .default
        )
        return textLayoutFragment
    }
}
