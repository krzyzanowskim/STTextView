//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

/// Line number mapping for a single text replacement. Used to keep gutter markers attached to their lines.
package struct STGutterLineEdit {
    /// 1-based line containing the start of the replaced range.
    let line: Int
    let startsAtLineStart: Bool
    let endsAtLineStart: Bool
    let isInsertion: Bool
    let removedLineBreaks: Int
    let insertedLineBreaks: Int

    /// Returns `nil` when the replacement neither removes nor inserts line breaks.
    /// - Parameters:
    ///   - text: The text before the replacement.
    ///   - range: The replaced range in `text`.
    ///   - replacement: The replacement string.
    package init?(text: NSString, range: NSRange, replacement: String) {
        let removedLineBreaks = Self.lineBreakCount(in: text, range: range)
        let replacement = replacement as NSString
        let insertedLineBreaks = Self.lineBreakCount(in: replacement, range: NSRange(location: 0, length: replacement.length))
        guard removedLineBreaks > 0 || insertedLineBreaks > 0 else {
            return nil
        }

        self.line = Self.lineBreakCount(in: text, range: NSRange(location: 0, length: range.location)) + 1
        self.startsAtLineStart = Self.isLineStart(range.location, in: text)
        self.endsAtLineStart = removedLineBreaks > 0 && Self.isLineStart(NSMaxRange(range), in: text)
        self.isInsertion = range.length == 0
        self.removedLineBreaks = removedLineBreaks
        self.insertedLineBreaks = insertedLineBreaks
    }

    /// The line number after the replacement, or `nil` when the line was removed.
    package func lineNumber(for lineNumber: Int) -> Int? {
        let delta = insertedLineBreaks - removedLineBreaks

        if lineNumber < line {
            return lineNumber
        }

        if lineNumber == line {
            // Content inserted in front of the line pushes it down; removal spanning its line break deletes it.
            if startsAtLineStart, isInsertion {
                return lineNumber + delta
            }
            if startsAtLineStart, removedLineBreaks > 0 {
                return nil
            }
            return lineNumber
        }

        let lastAffectedLine = line + removedLineBreaks
        if lineNumber < lastAffectedLine {
            return nil
        }
        if lineNumber == lastAffectedLine {
            return endsAtLineStart ? lineNumber + delta : nil
        }
        return lineNumber + delta
    }

    /// Moves markers to their new lines and drops markers of removed lines.
    /// A marker that stays on its line wins over one moved onto that line.
    package func updatedMarkers<Marker>(_ markers: [Marker], lineNumber: (Marker) -> Int, moved: (Marker, Int) -> Marker) -> [Marker] {
        var updatedMarkers: [Marker] = []
        for marker in markers {
            let oldLineNumber = lineNumber(marker)
            guard let newLineNumber = self.lineNumber(for: oldLineNumber) else {
                continue
            }

            let updatedMarker = newLineNumber == oldLineNumber ? marker : moved(marker, newLineNumber)
            if let index = updatedMarkers.firstIndex(where: { lineNumber($0) == newLineNumber }) {
                if newLineNumber == oldLineNumber {
                    updatedMarkers[index] = updatedMarker
                }
            } else {
                updatedMarkers.append(updatedMarker)
            }
        }
        return updatedMarkers
    }

    private static func isLineStart(_ location: Int, in text: NSString) -> Bool {
        var paragraphStart = 0
        text.getParagraphStart(&paragraphStart, end: nil, contentsEnd: nil, for: NSRange(location: location, length: 0))
        return paragraphStart == location
    }

    private static func lineBreakCount(in text: NSString, range: NSRange) -> Int {
        var count = 0
        var location = range.location
        let end = NSMaxRange(range)
        while location < end {
            var paragraphEnd = 0
            var contentsEnd = 0
            text.getParagraphStart(nil, end: &paragraphEnd, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))
            guard contentsEnd < end, contentsEnd < paragraphEnd else {
                break
            }
            count += 1
            location = paragraphEnd
        }
        return count
    }
}
