//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md


import Cocoa

extension NSTextLayoutManager {

    var textSelectionsRanges: [NSTextRange] {
        textSelections.flatMap(\.textRanges)
    }

    var insertionPointLocation: NSTextLocation? {
        guard let textSelection = textSelections.first(where: { !$0.isLogical }) else {
            return nil
        }
        return textSelectionNavigation.resolvedInsertionLocation(for: textSelection, writingDirection: .leftToRight)
    }

}

extension NSTextLayoutFragment {

    var hasExtraLineFragment: Bool {
        textLineFragments.contains(where: \.isExtraLineFragment)
    }

    func textLineFragment(at searchLocation: NSTextLocation, in textContentManager: NSTextContentManager? = nil) -> NSTextLineFragment? {
        guard let textContentManager = textContentManager ?? textLayoutManager?.textContentManager else {
            assertionFailure()
            return nil
        }

        let searchNSLocation = NSRange(searchLocation, in: textContentManager).location
        let fragmentLocation = NSRange(rangeInElement.location, in: textContentManager).location
        return textLineFragments.first { lineFragment in
            let absoluteLineRange = NSRange(location: lineFragment.characterRange.location + fragmentLocation, length: lineFragment.characterRange.length)
            return absoluteLineRange.contains(searchNSLocation)
        }
    }
}

extension NSTextLineFragment {

    // textLineFragment.characterRange.isEmpty the extra line fragment at the end of a document.
    var isExtraLineFragment: Bool {
        characterRange.isEmpty
    }

}
