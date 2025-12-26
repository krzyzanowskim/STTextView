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
        if let range, range.isEmpty {
            return nil
        }

        // fast path
        if let textContentStorage = self as? NSTextContentStorage {
            if let range {
                return textContentStorage.textStorage?.attributedSubstring(from: NSRange(range, in: self))
            } else {
                return textContentStorage.textStorage
            }
        }

        // slow path
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
    
    /// Returns an array of text elements that intersect with the range you specify.
    /// - Parameter range: An NSTextRange that describes the range of text to process.
    /// - Returns: An array of NSTextElement.
    ///
    /// This method can return a set of elements that don’t fill the entire range if the entire range isn’t synchronously available. Uses `enumerateTextElements(from:options:using:)` to fill the array.
    ///
    /// This is working implementation, in contrary to buggy `textElements(for:)` (FB10019859)
    func textElementsNotBuggy(for range: NSTextRange) -> [NSTextElement] {
        var elements: [NSTextElement] = []

        if range.location == documentRange.endLocation {
            // last element is technically beyond the textElement.endLocation
            // but still.
            enumerateTextElements(from: range.endLocation, options: .reverse) { textElement in
                elements.append(textElement)
                return false
            }
        } else {
            enumerateTextElements(from: range.location, options: []) { textElement in
                var shouldCountinue = true
                if let elementRange = textElement.elementRange {
                    if range.intersects(elementRange) || elementRange.contains(range.location) {
                        elements.append(textElement)
                    } else {
                        shouldCountinue = false
                    }
                }

                return shouldCountinue
            }
        }
        return elements
    }
}
