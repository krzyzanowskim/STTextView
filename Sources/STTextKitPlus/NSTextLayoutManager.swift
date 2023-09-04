//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension NSTextLayoutManager {
    
    public func textLineFragment(at location: NSTextLocation) -> NSTextLineFragment? {
        textLayoutFragment(for: location)?.textLineFragment(at: location)
    }

    public func textLineFragment(at point: CGPoint) -> NSTextLineFragment? {
        textLayoutFragment(for: point)?.textLineFragment(at: point)
    }

}

extension NSTextLayoutManager {

    /// Returns a location of text produced by a tap or click at the point you specify.
    /// - Parameters:
    ///   - point: A CGPoint that represents the location of the tap or click.
    ///   - containerLocation: A NSTextLocation that describes the contasiner location.
    /// - Returns: A location
    public func location(interactingAt point: CGPoint, inContainerAt containerLocation: NSTextLocation) -> NSTextLocation? {
        guard let lineFragmentRange = lineFragmentRange(for: point, inContainerAt: containerLocation) else {
            return nil
        }

        var distance: CGFloat = CGFloat.infinity
        var caretLocation: NSTextLocation? = nil
        enumerateCaretOffsetsInLineFragment(at: lineFragmentRange.location) { caretOffset, location, leadingEdge, stop in
            let localDistance = abs(caretOffset - point.x)
            if leadingEdge {
                if localDistance < distance{
                    distance = localDistance
                    caretLocation = location
                } else if localDistance > distance{
                    stop.pointee = true
                }
            }
        }

        return caretLocation
    }
}

extension NSTextLayoutManager {

    ///  A text segment is both logically and visually contiguous portion of the text content inside a line fragment.
    public func textSegmentFrame(at location: NSTextLocation, type: NSTextLayoutManager.SegmentType, options: SegmentOptions = [.upstreamAffinity]) -> CGRect? {
        textSegmentFrame(in: NSTextRange(location: location), type: type, options: options)
    }

    /// A text segment is both logically and visually contiguous portion of the text content inside a line fragment.
    public func textSegmentFrame(in textRange: NSTextRange, type: NSTextLayoutManager.SegmentType, options: SegmentOptions = [.upstreamAffinity, .rangeNotRequired]) -> CGRect? {
        var result: CGRect? = nil
        // .upstreamAffinity: When specified, the segment is placed based on the upstream affinity for an empty range.
        //
        // In the context of text editing, upstream affinity means that the selection is biased towards the preceding or earlier portion of the text,
        // while downstream affinity means that the selection is biased towards the following or later portion of the text. The affinity helps determine
        // the behavior of the text selection when the text is modified or manipulated.
        enumerateTextSegments(in: textRange, type: type, options: options) { _, textSegmentFrame, _, _ -> Bool in
            result = result?.union(textSegmentFrame) ?? textSegmentFrame
            return true
        }
        return result
    }

}

extension NSTextLayoutManager {

    /// Enumerates the text layout fragments in the specified range.
    ///
    /// - Parameters:
    ///   - range: The location where you start the enumeration.
    ///   - options: One or more of the available NSTextLayoutFragmentEnumerationOptions
    ///   - block: A closure you provide that determines if the enumeration finishes early.
    /// - Returns: An NSTextLocation, or nil. If the method enumerates at least one fragment, it returns the edge of the enumerated range.
    @discardableResult public func enumerateTextLayoutFragments(in range: NSTextRange, options: NSTextLayoutFragment.EnumerationOptions = [], using block: (NSTextLayoutFragment) -> Bool) -> NSTextLocation? {
        enumerateTextLayoutFragments(from: range.location, options: options) { layoutFragment in
            let shouldContinue = layoutFragment.rangeInElement.location <= range.endLocation
            if !shouldContinue {
                return false
            }

            return shouldContinue && block(layoutFragment)
        }

    }

}

extension NSTextLayoutManager {

    public var insertionPointLocations: [NSTextLocation] {
        insertionPointSelections.flatMap(\.textRanges).map(\.location).sorted(by: { $0 < $1 })
    }

    public var insertionPointSelections: [NSTextSelection] {
        textSelections.filter(_textSelectionInsertionPointFilter)
    }
}

private let _textSelectionInsertionPointFilter: (NSTextSelection) -> Bool = { textSelection in
    !textSelection.isLogical
    && !textSelection.isTransient // questionable condition (?)
    && textSelection.textRanges.contains { textRange in
        textRange.isEmpty
    }
}
