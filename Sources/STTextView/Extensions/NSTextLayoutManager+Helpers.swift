//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus

extension NSTextLayoutManager {

    /// A String in range
    /// - Parameter range: Text range
    /// - Returns: String in the range
    func substring(in range: NSTextRange) -> String {
        guard !range.isEmpty else { return "" }
        var output = String()
        if let textContentManager {
            output.reserveCapacity(range.length(in: textContentManager))
        } else {
            output.reserveCapacity(128)
        }
        enumerateSubstrings(from: range.location, options: .byComposedCharacterSequences) { (substring, substringRange, _, stop) in
            let shouldContinue = substringRange.location <= range.endLocation
            if !shouldContinue {
                stop.pointee = true
                return
            }

            if let substring = substring {
                output += substring
            }
        }
        return output
    }

    func enumerateSubstrings(in range: NSTextRange, options: String.EnumerationOptions = [], using block: (String?, NSTextRange, NSTextRange?, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateSubstrings(from: range.location, options: options) { substring, substringRange, enclosingRange, stop in
            let shouldContinue = substringRange.location <= range.endLocation
            if !shouldContinue {
                stop.pointee = true
                return
            }

            block(substring, substringRange, enclosingRange, stop)
        }
    }

    struct TextSelectionRangesOptions: OptionSet {
        let rawValue: UInt
        static let withoutInsertionPoints = TextSelectionRangesOptions(rawValue: 1 << 0)
    }

    func textSelectionsRanges(_ options: TextSelectionRangesOptions = []) -> [NSTextRange] {
        if options.contains(.withoutInsertionPoints) {
            return textSelections.flatMap(\.textRanges).filter({ !$0.isEmpty }).sorted(by: { $0.location < $1.location })
        } else {
            return textSelections.flatMap(\.textRanges).sorted(by: { $0.location < $1.location })
        }
    }

    func textSelectionsString() -> String? {
        textSelectionsRanges(.withoutInsertionPoints).compactMap { textRange in
            substring(in: textRange)
        }.joined(separator: "\n")
    }

    func textSelectionsAttributedString() -> NSAttributedString? {
        textAttributedString(in: textSelectionsRanges(.withoutInsertionPoints))
    }

    func textAttributedString(in textRange: NSTextRange) -> NSAttributedString? {
        textAttributedString(in: [textRange])
    }

    func textAttributedString(in textRanges: [NSTextRange]) -> NSAttributedString? {
        let attributedString = textRanges.reduce(NSMutableAttributedString()) { partialResult, range in
            if let attributedString = textContentManager?.attributedString(in: range) {
                if partialResult.length != 0 {
                    partialResult.append(NSAttributedString(string: "\n"))
                }
                partialResult.append(attributedString)
            }
            return partialResult
        }

        if attributedString.length == 0 {
            return nil
        }
        return attributedString
    }

    /// Enumerates rendering attributes in the range you provide.
    ///
    /// It enumerates only ranges with rendering attributes specified.
    /// This method only enumerates ranges with text that specify rendering attributes. Returning false from block breaks out of the enumeration.
    ///
    /// - Parameters:
    ///   - range: The location at which to start the enumeration.
    ///   - reverse: Whether to start the enumeration from the end of the range.
    ///   - block: A closure you provide to determine if the enumeration finishes early.
    func enumerateRenderingAttributes(in range: NSTextRange, reverse: Bool, using block: (NSTextLayoutManager, [NSAttributedString.Key : Any], NSTextRange) -> Bool) {
        enumerateRenderingAttributes(from: range.location, reverse: reverse) { textLayoutManager, attributes, textRange in
            let shouldContinue = textRange.location <= range.endLocation
            if !shouldContinue {
                return false
            }

            return shouldContinue && block(textLayoutManager, attributes, textRange)
        }
    }

    /// Enumerates text layout frames for the range you provide.
    /// - Parameters:
    ///   - range: The range as an NSTextRange.
    ///   - block: A closure called for each rectangle in the range. One or more calls.
    @available(*, unavailable, message: "Work in progress")
    func enumerateTextLayoutFrames(in range: NSTextRange, using block: (_ frame: CGRect, _ frameRange: NSTextRange) -> Void) {
        enumerateTextLayoutFragments(in: range) { layoutFragment in
            for lineFragment in layoutFragment.textLineFragments {
                guard let lineTextRange = lineFragment.textRange(in: layoutFragment) else {
                    continue
                }

                var x = lineFragment.typographicBounds.minX
                let y = layoutFragment.layoutFragmentFrame.minY + lineFragment.typographicBounds.minY
                var width = lineFragment.typographicBounds.width
                let height = lineFragment.typographicBounds.height
                var startLocation = lineTextRange.location
                var endLocation = lineTextRange.endLocation

                if lineTextRange.contains(range.location) {
                    // cut off everything before location
                    let leadingOffset = lineFragment.locationForCharacter(at: offset(from: lineTextRange.location, to: range.location))
                    x = x + leadingOffset.x
                    width = width - leadingOffset.x

                    if range.location > lineTextRange.location {
                        startLocation = range.location
                    }
                }

                if lineTextRange.contains(range.endLocation) {
                    // cut off everything after endLocation
                    let trailingOffset = lineFragment.locationForCharacter(at: offset(from: range.endLocation, to: lineTextRange.endLocation))
                    width = width - trailingOffset.x

                    if range.endLocation < lineTextRange.endLocation {
                        endLocation = range.endLocation
                    }
                }

                if let frameTextRange = NSTextRange(location: startLocation, end: endLocation) {
                    block(CGRect(x: x, y: y, width: width, height: height), frameTextRange)
                }

            }

            return true
        }
    }
}

