//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension NSTextLayoutManager {

    func destinationSelection(
        from originTextSelection: NSTextSelection,
        in direction: NSTextSelectionNavigation.Direction,
        offset: Int
    ) -> NSTextSelection? {
        guard offset > 0 else {
            return originTextSelection
        }
        let destinationTextSelection = textSelectionNavigation.destinationSelection(
            for: originTextSelection,
            direction: direction,
            destination: .character,
            extending: false,
            confined: false
        )
        guard let destinationTextSelection else {
            return nil
        }
        return destinationSelection(
            from: destinationTextSelection,
            in: direction,
            offset: offset - 1
        )
    }

    func textLayoutFragmentAndTextLineFragment(
        at textLocation: NSTextLocation
    ) -> (NSTextLayoutFragment, NSTextLineFragment)? {
        guard let textLayoutFragment = textLayoutFragment(at: textLocation) else {
            return nil
        }
        let offset = offset(from: textLayoutFragment.rangeInElement.location, to: textLocation)
        let textLineFragments = textLayoutFragment.textLineFragments
        guard let textLineFragment = textLineFragments.first(where: { $0.characterRange.contains(offset) }) else {
            return nil
        }
        return (textLayoutFragment, textLineFragment)
    }
}

private extension NSTextLayoutManager {
    private func textLayoutFragment(at textLocation: NSTextLocation) -> NSTextLayoutFragment? {
        var result: NSTextLayoutFragment?
        enumerateTextLayoutFragments(from: textLocation) { textLayoutFragment in
            result = textLayoutFragment
            return false
        }
        return result
    }
}
