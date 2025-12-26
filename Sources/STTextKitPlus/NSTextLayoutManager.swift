// BSD 3-Clause License
//
// Copyright (c) Marcin Krzyżanowski
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#if os(macOS) && !targetEnvironment(macCatalyst)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

extension NSTextLayoutManager {

    /// Extra line layout fragment.
    ///
    /// Only valid when ``state`` greater than NSTextLayoutFragment.State.estimatedUsageBounds
    @nonobjc public func extraLineTextLayoutFragment() -> NSTextLayoutFragment? {
        var extraTextLayoutFragment: NSTextLayoutFragment?
        enumerateTextLayoutFragments(from: nil, options: .reverse) { textLayoutFragment in
            if textLayoutFragment.state.rawValue > NSTextLayoutFragment.State.estimatedUsageBounds.rawValue,
               textLayoutFragment.isExtraLineFragment
            {
                extraTextLayoutFragment = textLayoutFragment
            }
            return false
        }
        return extraTextLayoutFragment
    }

    /// Extra line fragment.
    ///
    /// Only valid when ``state`` greater than NSTextLayoutFragment.State.estimatedUsageBounds
    @nonobjc public func extraLineTextLineFragment() -> NSTextLineFragment? {
        if let textLayoutFragment = extraLineTextLayoutFragment() {
            let textLineFragments = textLayoutFragment.textLineFragments
            if textLineFragments.count > 1, let lastTextLineFragment = textLineFragments.last,
               lastTextLineFragment.isExtraLineFragment
            {
                return lastTextLineFragment
            }
        }
        return nil
    }

}


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
    ///   - containerLocation: A NSTextLocation that describes the container location.
    /// - Returns: A location
    @available(*, deprecated, renamed: "caretLocation(interactingAt:inContainerAt:)")
    public func location(interactingAt point: CGPoint, inContainerAt containerLocation: NSTextLocation) -> NSTextLocation? {
        caretLocation(interactingAt: point, inContainerAt: containerLocation)
    }

    public struct CaretLocationOptions : OptionSet, @unchecked Sendable {
        public var rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Allow point outside text layout fragment frame
        public static var allowOutside = CaretLocationOptions(rawValue: 1 << 0)
    }

    /// Returns a location of text produced by a tap or click at the point you specify.
    /// - Parameters:
    ///   - point: A CGPoint that represents the location of the tap or click.
    ///   - containerLocation: A NSTextLocation that describes the container location.
    /// - Returns: A location
    ///
    /// Note: For proper caret positioning at soft line breaks, prefer `caretLocationWithAffinity`
    /// which also returns the appropriate affinity for the position.
    public func caretLocation(interactingAt point: CGPoint, options: CaretLocationOptions = [], inContainerAt containerLocation: NSTextLocation) -> NSTextLocation? {
        if !options.contains(.allowOutside) {
            // Is point outside the frame?
            if let layoutFragmentFrame = textLayoutFragment(for: point)?.layoutFragmentFrame, !layoutFragmentFrame.contains(point) {
                return nil
            }
        }

        // Delegate to caretLocationWithAffinity and return just the location
        return caretLocationWithAffinity(interactingAt: point, inContainerAt: containerLocation)?.0
    }

    /// Returns a location and affinity for text produced by a tap or click at the point you specify.
    /// This version determines the correct affinity for soft line breaks - upstream for end-of-line clicks.
    public func caretLocationWithAffinity(interactingAt point: CGPoint, inContainerAt containerLocation: NSTextLocation) -> (NSTextLocation, NSTextSelection.Affinity)? {
        guard let lineFragmentRange = lineFragmentRange(for: point, inContainerAt: containerLocation) else {
            return nil
        }

        var distance: CGFloat = CGFloat.infinity
        var caretLocation: NSTextLocation? = nil
        var firstCaretOffset: CGFloat? = nil
        var lastCaretOffset: CGFloat? = nil
        var lastCaretLocOffset: Int = -1

        enumerateCaretOffsetsInLineFragment(at: lineFragmentRange.location) { caretOffset, location, leadingEdge, stop in
            let locOffset = textContentManager?.offset(from: documentRange.location, to: location) ?? -1

            // Track first caret offset (leading edge only)
            if firstCaretOffset == nil && leadingEdge {
                firstCaretOffset = caretOffset
            }
            lastCaretOffset = caretOffset
            lastCaretLocOffset = locOffset

            let localDistance = abs(caretOffset - point.x)
            if leadingEdge {
                if localDistance < distance {
                    distance = localDistance
                    caretLocation = location
                } else if localDistance > distance {
                    stop.pointee = true
                }
            } else {
                // Also consider trailing edges
                if localDistance < distance {
                    distance = localDistance
                    caretLocation = location
                }
            }
        }

        guard let result = caretLocation, let lastOffset = lastCaretOffset else {
            return nil
        }

        // Fix for wrapped lines: if we landed at the START of a line fragment,
        // but the click was far to the RIGHT of the first caret position,
        // we probably clicked past the end of the previous wrapped line.
        // Return the end of that previous line with upstream affinity.
        if let firstOffset = firstCaretOffset,
           result == lineFragmentRange.location, // We landed at line start
           point.x > firstOffset + 50, // Click is significantly to the right of line start
           let prevCharLocation = textContentManager?.location(lineFragmentRange.location, offsetBy: -1),
           prevCharLocation >= documentRange.location,
           prevCharLocation != lineFragmentRange.location { // Ensure we're going to a different line
            // Find the last caret position in the line fragment containing prevCharLocation
            var prevLastCaretLocOffset: Int = -1
            enumerateCaretOffsetsInLineFragment(at: prevCharLocation) { _, location, leadingEdge, _ in
                if leadingEdge {
                    prevLastCaretLocOffset = textContentManager?.offset(from: documentRange.location, to: location) ?? -1
                }
            }
            // Return position after last char on previous line with upstream affinity
            if prevLastCaretLocOffset >= 0,
               let endOfPrevLine = textContentManager?.location(documentRange.location, offsetBy: prevLastCaretLocOffset + 1),
               endOfPrevLine <= documentRange.endLocation {
                return (endOfPrevLine, .upstream)
            }
        }

        // Determine if clicking past the end of text on this line
        let clickedPastLineEnd = point.x > lastOffset

        if clickedPastLineEnd {
            // To place caret at the END of this visual line (after trailing spaces),
            // we need the position ONE PAST the last character, with upstream affinity.
            // The trailing edge of the last char and leading edge of the next char
            // are the same visual position, but with different affinities.
            if let nextLocation = textContentManager?.location(documentRange.location, offsetBy: lastCaretLocOffset + 1),
               nextLocation <= documentRange.endLocation {
                return (nextLocation, .upstream)
            }
        }

        return (result, .downstream)
    }
}

extension NSTextLayoutManager {

    /// Typographic bounds of the range.
    /// - Parameter textRange: The range.
    /// - Returns: Typographic bounds of the range.
    ///
    /// Returns a union of each segment frame in the range, which may be larger than the area needed to layout the range.
    public func typographicBounds(in textRange: NSTextRange) -> CGRect? {
        textSegmentFrame(in: textRange, type: .standard, options: [.upstreamAffinity, .rangeNotRequired])
    }

    ///  A text segment is both logically and visually contiguous portion of the text content inside a line fragment.
    public func textSegmentFrame(at location: NSTextLocation, type: NSTextLayoutManager.SegmentType, options: SegmentOptions = [.upstreamAffinity]) -> CGRect? {
        textSegmentFrame(in: NSTextRange(location: location), type: type, options: options)
    }

    /// A text segment is both logically and visually contiguous portion of the text content inside a line fragment.
    /// Text segment is a logically and visually contiguous portion of the text content inside a line fragment that you specify with a single text range.
    /// The framework enumerates the segments visually from left to right.
    public func textSegmentFrame(in textRange: NSTextRange, type: NSTextLayoutManager.SegmentType, options: SegmentOptions = [.upstreamAffinity, .rangeNotRequired]) -> CGRect? {
        var result: CGRect? = nil
        // .upstreamAffinity: When specified, the segment is placed based on the upstream affinity for an empty range.
        //
        // In the context of text editing, upstream affinity means that the selection is biased towards the preceding or earlier portion of the text,
        // while downstream affinity means that the selection is biased towards the following or later portion of the text. The affinity helps determine
        // the behavior of the text selection when the text is modified or manipulated.

        // FB15131180: Extra line fragment frame is not correct, that affects enumerateTextSegments as well.
        enumerateTextSegments(in: textRange, type: type, options: options) { textSegmentRange, textSegmentFrame, baselinePosition, textContainer -> Bool in
            result = result?.union(textSegmentFrame) ?? textSegmentFrame
            return true
        }
        return result
    }

    /// Enumerates text segments in the text range you provide.
    public func textSegmentFrames(in textRange: NSTextRange, type: NSTextLayoutManager.SegmentType, options: SegmentOptions = [.upstreamAffinity, .rangeNotRequired]) -> [CGRect] {
        var result: [CGRect] = []
        enumerateTextSegments(in: textRange, type: type, options: options) { textSegmentRange, textSegmentFrame, baselinePosition, textContainer -> Bool in
            result.append(textSegmentFrame)
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
    !textSelection.isLogical && textSelection.textRanges.contains(where: \.isEmpty)
}
