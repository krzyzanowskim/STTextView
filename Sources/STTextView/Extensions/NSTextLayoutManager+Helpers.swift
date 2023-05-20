//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension NSTextLayoutManager {

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

    func textSelectionsAttributedString() -> NSAttributedString? {
        let attributedString = textSelections.flatMap(\.textRanges).reduce(NSMutableAttributedString()) { partialResult, range in
            if let attributedString = textContentManager?.attributedString(in: range) {
                partialResult.append(attributedString)
            }
            return partialResult
        }

        if attributedString.length == 0 {
            return nil
        }
        return attributedString
    }

    ///  A text segment is both logically and visually contiguous portion of the text content inside a line fragment.
    public func textSelectionSegmentFrame(at location: NSTextLocation, type: NSTextLayoutManager.SegmentType) -> CGRect? {
        textSelectionSegmentFrame(in: NSTextRange(location: location), type: type)
    }

    public func textSelectionSegmentFrame(in textRange: NSTextRange, type: NSTextLayoutManager.SegmentType) -> CGRect? {
        var result: CGRect? = nil
        // .upstreamAffinity: When specified, the segment is placed based on the upstream affinity for an empty range.
        //
        // In the context of text editing, upstream affinity means that the selection is biased towards the preceding or earlier portion of the text,
        // while downstream affinity means that the selection is biased towards the following or later portion of the text. The affinity helps determine
        // the behavior of the text selection when the text is modified or manipulated.
        enumerateTextSegments(in: textRange, type: type, options: [.rangeNotRequired, .upstreamAffinity]) { _, textSegmentFrame, _, _ -> Bool in
            result = textSegmentFrame
            return true
        }
        return result
    }

    public func textLineFragment(at location: NSTextLocation) -> NSTextLineFragment? {
        textLayoutFragment(for: location)?.textLineFragment(at: location)
    }

    public func textLineFragment(at point: CGPoint) -> NSTextLineFragment? {
        textLayoutFragment(for: point)?.textLineFragment(at: point)
    }



}

extension NSTextLayoutManager {

    /// Returns a location of text produced by a tap or click at the point you specify.
    public func location(interactingAt point: CGPoint, inContainerAt containerLocation: NSTextLocation) -> NSTextLocation? {
        guard let lineFragmentRange = lineFragmentRange(for: point, inContainerAt: containerLocation)
        else {
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

extension NSTextLayoutFragment {

    @available(*, deprecated, message: "Unused")
    var hasExtraLineFragment: Bool {
        textLineFragments.last?.isExtraLineFragment ?? false
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

    func textLineFragment(at location: CGPoint, in textContentManager: NSTextContentManager? = nil) -> NSTextLineFragment? {
        textLineFragments.first { lineFragment in
            CGRect(origin: layoutFragmentFrame.origin, size: lineFragment.typographicBounds.size).contains(location)
        }
    }
}

extension NSTextLineFragment {

    var isExtraLineFragment: Bool {
        // textLineFragment.characterRange.isEmpty the extra line fragment at the end of a document.
        characterRange.isEmpty
    }

}
