//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension NSTextLayoutManager {

    func location(
        from location: NSTextLocation,
        in direction: NSTextSelectionNavigation.Direction,
        offset: Int
    ) -> NSTextLocation? {
        guard var naiveTargetLocation = destinationSelection(
            from: location,
            in: direction,
            offset: offset
        )?.textRanges.first?.location else {
            return nil
        }
        guard direction == .up || direction == .down else {
            return naiveTargetLocation
        }
        // Make sure we keep the selection at the same location in line fragments as we move up and down.
        if naiveTargetLocation.compare(documentRange.endLocation) == .orderedSame {
            naiveTargetLocation = self.location(documentRange.endLocation, offsetBy: -1) ?? naiveTargetLocation
        }
        guard let (originLine, originLineFragment) = textLayoutFragmentAndTextLineFragment(at: location),
              let (targetLine, targetLineFragment) = textLayoutFragmentAndTextLineFragment(at: naiveTargetLocation) else {
            return nil
        }
        let locationOffsetInOriginLine = self.offset(from: originLine.rangeInElement.location, to: location)
        let originPointOnScreen = originLineFragment.locationForCharacter(at: locationOffsetInOriginLine)
        let targetPointOnScreen = CGPoint(x: originPointOnScreen.x, y: targetLineFragment.typographicBounds.minY)
        var offsetInTargetLine = targetLineFragment.characterIndex(for: targetPointOnScreen)
        if offsetInTargetLine == NSNotFound {
            offsetInTargetLine = targetLineFragment.characterRange.length - 1
        }
        guard let targetLocation = self.location(targetLine.rangeInElement.location, offsetBy: offsetInTargetLine) else {
            return nil
        }
        let movementRange = if location.compare(targetLocation) == .orderedAscending {
            NSTextRange(location: location, end: targetLocation)
        } else {
            NSTextRange(location: targetLocation, end: location)
        }
        guard let movementRange else {
            return nil
        }
        let lineFragmentsMovedBy = textLineFragments(in: movementRange)
        guard offset <= lineFragmentsMovedBy.count - 1 else {
            // If we were unable to move the requested number of line fragments then we move to the bounds of the document. This behavior is expected by UITextInput and ensures it can be navigated correctly using the keyboard.
            return direction == .up ? documentRange.location : documentRange.endLocation
        }
        return targetLocation
    }

}

private extension NSTextLayoutManager {
    private func destinationSelection(
        from sourceLocation: NSTextLocation,
        in direction: NSTextSelectionNavigation.Direction,
        offset: Int
    ) -> NSTextSelection? {
        let sourceTextSelection = NSTextSelection(sourceLocation, affinity: .downstream)
        var result: NSTextSelection? = sourceTextSelection
        for _ in 0 ..< offset {
            result = textSelectionNavigation.destinationSelection(
                for: result ?? sourceTextSelection,
                direction: direction,
                destination: .character,
                extending: false,
                confined: false
            )
        }
        return result
    }

    private func textLayoutFragment(at textLocation: NSTextLocation) -> NSTextLayoutFragment? {
        var result: NSTextLayoutFragment?
        enumerateTextLayoutFragments(from: textLocation) { textLayoutFragment in
            result = textLayoutFragment
            return false
        }
        return result
    }

    private func textLayoutFragmentAndTextLineFragment(
        at textLocation: NSTextLocation
    ) -> (NSTextLayoutFragment, NSTextLineFragment)? {
        guard let textLayoutFragment = textLayoutFragment(at: textLocation) else {
            return nil
        }
        let offset = offset(from: textLayoutFragment.rangeInElement.location, to: textLocation)
        guard let textLineFragment = textLayoutFragment.textLineFragments.first(
            where: { $0.characterRange.contains(offset) }
        ) else {
            return nil
        }
        return (textLayoutFragment, textLineFragment)
    }

    private func textLineFragments(in textRange: NSTextRange) -> [NSTextLineFragment] {
        var result: [NSTextLineFragment] = []
        enumerateTextLayoutFragments(from: textRange.location) { textLayoutFragment in
            result += textLayoutFragment.textLineFragments
            return textLayoutFragment.rangeInElement.endLocation.compare(textRange.endLocation) != .orderedDescending
        }
        return result
    }
}
