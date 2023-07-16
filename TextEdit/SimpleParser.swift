//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import NaturalLanguage

class SimpleParser {

    struct Word: CustomStringConvertible {
        let string: String

        var description: String {
            string
        }
    }

    static func words(_ string: String) -> AsyncStream<Word> {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = string

        return AsyncStream { continuation in
            tokenizer.enumerateTokens(in: string.startIndex..<string.endIndex) { tokenRange, attributes in
                if !attributes.contains(.numeric) {
                    let token = String(string[tokenRange])
                    continuation.yield(Word(string: token))
                }
                return !Task.isCancelled
            }

            continuation.finish()
        }
    }
}
