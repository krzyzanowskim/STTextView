//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

import STTextKitPlus

package struct TextSelectionRangesOptions: OptionSet {
    package let rawValue: UInt
    package static let withoutInsertionPoints = TextSelectionRangesOptions(rawValue: 1 << 0)
    package static let withInsertionPoints = TextSelectionRangesOptions(rawValue: 1 << 1)

    package init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

package extension NSTextLayoutManager {

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

    func textSelectionsRanges(_ options: TextSelectionRangesOptions = .withInsertionPoints) -> [NSTextRange] {
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

    func textAttributedString(at location: any NSTextLocation) -> NSAttributedString? {
        if let range = NSTextRange(location: location, end: self.location(location, offsetBy: 1)), !range.isEmpty {
            return textAttributedString(in: range)
        }

        return nil
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
}
