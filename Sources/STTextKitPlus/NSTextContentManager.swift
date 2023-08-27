//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

public extension NSTextContentManager {

    func location(at offset: Int) -> NSTextLocation? {
        location(documentRange.location, offsetBy: offset)
    }

    var length: Int {
        offset(from: documentRange.location, to: documentRange.endLocation)
    }

    func location(line lineIdx: Int, character characterIdx: Int? = 0) -> NSTextLocation? {
        let linesTextElements = textElements(for: documentRange)
        guard linesTextElements.indices ~= lineIdx else {
            // https://forums.swift.org/t/invalid-diagnostic-location-after-text-edit/54761
            // logger.warning("Invalid region line: \(lineIdx). ")
            return nil
        }

        guard let startLocation = linesTextElements[lineIdx].elementRange?.location else {
            return nil
        }

        return location(startLocation, offsetBy: characterIdx ?? 0)
    }

    func position(_ location: NSTextLocation) -> (row: Int, column: Int)? {
        let linesElements = textElements(for: documentRange)
        if linesElements.isEmpty {
            return nil
        }

        let lineIdx: Int?
        if location == documentRange.endLocation {
            lineIdx = max(0, linesElements.count - 1)
        } else if let foundLineIdx = linesElements.firstIndex(where: { $0.elementRange!.contains(location) }) {
            lineIdx = foundLineIdx
        } else {
            lineIdx = nil
        }

        guard let lineIdx else {
            return nil
        }

        let column = offset(from: linesElements[lineIdx].elementRange!.location, to: location)
        return (row: lineIdx, column: column)
    }

    /// Attributed string for the range
    /// - Parameter range: Text range, or nil for the whole document.
    /// - Returns: Attributed string, or nil.
    func attributedString(in range: NSTextRange?) -> NSAttributedString? {
        if let range {
            precondition(range.isEmpty == false)
        }

        if range != nil, range?.isEmpty == true {
            return nil
        }

        let result = NSMutableAttributedString()
        result.beginEditing()
        enumerateTextElements(from: range?.location) { textElement in
            if let range = range,
               let textParagraph = textElement as? NSTextParagraph,
               let elementRange = textElement.elementRange,
               let textContentManager = textElement.textContentManager
            {
                var shouldStop = false
                var needAdjustment = false
                var constrainedElementRange = elementRange
                if elementRange.contains(range.location) {
                    // start location
                    constrainedElementRange = NSTextRange(location: range.location, end: constrainedElementRange.endLocation)!
                    needAdjustment = true
                }

                if elementRange.contains(range.endLocation) {
                    // end location
                    constrainedElementRange = NSTextRange(location: constrainedElementRange.location, end: range.endLocation)!
                    needAdjustment = true
                    shouldStop = true
                }

                if needAdjustment {
                    if let constrainedRangeInDocument = NSTextRange(location: constrainedElementRange.location, end: constrainedElementRange.endLocation) {
                        let constrainedRangeInDocumentLength = constrainedRangeInDocument.length(in: textContentManager)
                        let leadingOffset = textContentManager.offset(from: elementRange.location, to: constrainedElementRange.location)

                        // translate contentRangeInDocument from document namespace to textElement.attributedString namespace
                        let nsRangeInDocumentDocument = NSRange(
                            location: leadingOffset,
                            length: constrainedRangeInDocumentLength
                        )

                        result.append(
                            textParagraph.attributedString.attributedSubstring(from: nsRangeInDocumentDocument)
                        )
                    }
                } else {
                    result.append(
                        textParagraph.attributedString
                    )
                }

                if shouldStop {
                    return false
                }
            } else if range == nil, let textParagraph = textElement as? NSTextParagraph {
                result.append(
                    textParagraph.attributedString
                )
            }

            return true
        }

        result.fixAttributes(in: NSRange(location: 0, length: result.length))
        result.endEditing()
        if result.length == 0 {
            return nil
        }

        return result
    }
}
