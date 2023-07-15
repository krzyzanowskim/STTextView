//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

class SimpleParser {

    struct Word: CustomStringConvertible {
        let string: String

        var description: String {
            string
        }
    }

    static func words(_ string: String) -> AsyncStream<Word> {
        AsyncStream { continuation in
            var currentWord = ""
            var idx = string.startIndex
            while idx < string.endIndex {
                let c = string[idx]
                if c.isLetter {
                    currentWord.append(c.lowercased())
                } else if !currentWord.isEmpty {
                    continuation.yield(Word(string: currentWord))
                    currentWord.removeAll(keepingCapacity: true)
                }
                idx = string.index(after: idx)
            }

            if !currentWord.isEmpty {
                continuation.yield(Word(string: currentWord))
            }

            continuation.finish()
        }
    }
}
