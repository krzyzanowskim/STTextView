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
        textSelections.flatMap(\.textRanges).compactMap { textRange in
            substring(for: textRange)
        }.joined(separator: "\n")
    }

    func textSelectionsAttributedString() -> NSAttributedString? {
        textAttributedString(in: textSelections.flatMap(\.textRanges))
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

    @discardableResult
    func enumerateTextLayoutFragments(in range: NSTextRange, options: NSTextLayoutFragment.EnumerationOptions = [], using block: (NSTextLayoutFragment) -> Bool) -> NSTextLocation? {
        enumerateTextLayoutFragments(from: range.location, options: options) { layoutFragment in
            let shouldContinue = layoutFragment.rangeInElement.location <= range.endLocation
            if !shouldContinue {
                return false
            }

            return shouldContinue && block(layoutFragment)
        }
    }

}

extension NSTextLayoutFragment {

    @available(*, deprecated, message: "Unused")
    var hasExtraLineFragment: Bool {
        textLineFragments.last?.isExtraLineFragment ?? false
    }

}

extension NSTextLineFragment {

    var isExtraLineFragment: Bool {
        // textLineFragment.characterRange.isEmpty the extra line fragment at the end of a document.
        characterRange.isEmpty
    }

}
