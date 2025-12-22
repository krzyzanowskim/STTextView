//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import NaturalLanguage

class Tokenizer {

    struct Word: CustomStringConvertible {
        let string: String

        var description: String {
            string
        }
    }

    static func words(_ string: String, maxCount: Int = 512) -> AsyncStream<Word> {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = string

        return AsyncStream { continuation in
            var count = 0
            tokenizer.enumerateTokens(in: string.startIndex ..< string.endIndex) { tokenRange, attributes in
                if !attributes.contains(.numeric) {
                    let token = String(string[tokenRange]).lowercased()
                    continuation.yield(Word(string: token))
                    count += 1
                }

                if count > maxCount {
                    continuation.finish()
                    return false
                }

                return !Task.isCancelled
            }

            continuation.finish()
        }
    }
}
