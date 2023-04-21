//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

//
// Text selection is represented either
// - by multiple NSTextSelection instances with a single or more range.
// - by single NSTextSelection instance with multiple distinct ranges. All ranges in a text selection constitute a single insertion point.
//
// I don't have strong opinion whether one or another approach is better/worse. Boths seems equally broken in TextKit 2 anyway (see STTextContentStorage workarounds)
// As of today both are supported. Selections are processed in range order (asc/desc depending on the context)
//
// STTextView appends new insertion points as separate
//

import Cocoa

extension NSTextLayoutManager {

    @available(*, deprecated, message: "Use insertionPointLocations")
    public var insertionPointLocation: NSTextLocation? {
        guard let textSelection = insertionPointSelections.first else {
            return nil
        }

        return textSelection.textRanges.first?.location

        // FB11961508 NSTextSelectionNavigation.resolvedInsertionLocation sometimes crashes instead return nil
        // return textSelectionNavigation.resolvedInsertionLocation(for: textSelection, writingDirection: .leftToRight)
    }

    public var insertionPointLocations: [NSTextLocation] {
        insertionPointSelections.flatMap(\.textRanges).map(\.location)
    }

    public var insertionPointSelections: [NSTextSelection] {
        textSelections.filter(_textSelectionInsertionPointFilter)
    }

    /// Append insertion point.
    /// - Parameter point: A CGPoint that represents the location of the tap or click.
    internal func appendInsertionPointSelection(interactingAt point: CGPoint) {
        // Insertion points are either tge selections with a single empty range
        // or single selection with multiple empty ranges. Both cases are handled.
        // I didn't find an advantage of one approach over the other
        textSelections += textSelectionNavigation.textSelections(
            interactingAt: point,
            inContainerAt: documentRange.location,
            anchors: [],
            modifiers: [],
            selecting: false,
            bounds: usageBoundsForTextContainer
        )
    }
    
}

internal let _textSelectionInsertionPointFilter: (NSTextSelection) -> Bool = { textSelection in
       !textSelection.isLogical
    && !textSelection.isTransient
    && textSelection.textRanges.contains { textRange in
        textRange.isEmpty
    }
}
