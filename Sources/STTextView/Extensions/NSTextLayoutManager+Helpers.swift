//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension NSTextLayoutManager {

    public var insertionPointLocation: NSTextLocation? {
        guard let textSelection = textSelections.first(where: { !$0.isLogical }) else {
            return nil
        }
        return textSelectionNavigation.resolvedInsertionLocation(for: textSelection, writingDirection: .leftToRight)
    }

    func substring(for range: NSTextRange) -> String? {
        guard !range.isEmpty else { return nil }
        var output = String()
        output.reserveCapacity(128)
        enumerateSubstrings(from: range.location, options: .byComposedCharacterSequences, using:  { (substring, textRange, _, stop) in
            if let substring = substring {
                output += substring
            }

            if textRange.endLocation >= range.endLocation {
                stop.pointee = true
            }
        })
        return output
    }

    func textSelectionsString() -> String? {
        textSelections.flatMap(\.textRanges).reduce(nil) { partialResult, textRange in
            guard let substring = substring(for: textRange) else {
                return partialResult
            }

            var partialResult = partialResult
            if partialResult == nil {
                partialResult = ""
            }

            return partialResult?.appending(substring)
        }
    }

    ///  A text segment is both logically and visually contiguous portion of the text content inside a line fragment.
    public func textSelectionSegmentFrame(at location: NSTextLocation, type: NSTextLayoutManager.SegmentType) -> CGRect? {
        var result: CGRect? = nil
        enumerateTextSegments(in: NSTextRange(location: location), type: type, options: .rangeNotRequired) { _, textSegmentFrame, _, _ -> Bool in
            result = textSegmentFrame
            return false
        }
        return result
    }

    func caretOffsetsInLineFragment(at location: NSTextLocation) -> CGFloat? {
        var offset: CGFloat?
        enumerateCaretOffsetsInLineFragment(at: location) { caretOffset, location, leadingEdge, stop in
            offset = caretOffset
            stop.pointee = true
        }
        return offset
    }

    func textLineFragment(at location: NSTextLocation) -> NSTextLineFragment? {
        textLayoutFragment(for: location)?.textLineFragment(at: location)
    }
}

extension NSTextLayoutFragment {

    @available(*, deprecated, message: "Unused")
    var hasExtraLineFragment: Bool {
        textLineFragments.contains(where: \.isExtraLineFragment)
    }

    func textLineFragment(at location: NSTextLocation, in textContentManager: NSTextContentManager? = nil) -> NSTextLineFragment? {
        guard let textContentManager = textContentManager ?? textLayoutManager?.textContentManager else {
            assertionFailure()
            return nil
        }

        let searchNSLocation = NSRange(location, in: textContentManager).location
        let fragmentLocation = NSRange(rangeInElement.location, in: textContentManager).location
        return textLineFragments.first { lineFragment in
            let absoluteLineRange = NSRange(location: lineFragment.characterRange.location + fragmentLocation, length: lineFragment.characterRange.length)
            return absoluteLineRange.contains(searchNSLocation)
        }
    }

}

extension NSTextLineFragment {

    var isExtraLineFragment: Bool {
        // textLineFragment.characterRange.isEmpty the extra line fragment at the end of a document.
        characterRange.isEmpty
    }

}
