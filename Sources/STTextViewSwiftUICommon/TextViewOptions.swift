//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

/// Options for configuring TextView behavior.
@frozen
public struct TextViewOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // MARK: - Cross-platform options

    /// Breaks the text as needed to fit within the bounding box.
    public static let wrapLines = TextViewOptions(rawValue: 1 << 0)

    /// Highlighted selected line.
    public static let highlightSelectedLine = TextViewOptions(rawValue: 1 << 1)

    /// Enable to show line numbers in the gutter.
    public static let showLineNumbers = TextViewOptions(rawValue: 1 << 2)

    /// Disable smart quote substitution (e.g., " to "").
    public static let disableSmartQuotes = TextViewOptions(rawValue: 1 << 3)

    // MARK: - iOS only options

    /// Disable automatic capitalization.
    @available(macOS, unavailable)
    public static let disableAutocapitalization = TextViewOptions(rawValue: 1 << 4)

    /// Disable smart dash substitution (e.g., -- to —).
    @available(macOS, unavailable)
    public static let disableSmartDashes = TextViewOptions(rawValue: 1 << 5)

    /// Disable smart insert/delete behavior.
    @available(macOS, unavailable)
    public static let disableSmartInsertDelete = TextViewOptions(rawValue: 1 << 6)

    // MARK: - macOS only options

    /// Disable automatic text replacement.
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    public static let disableTextReplacement = TextViewOptions(rawValue: 1 << 7)

    /// Disable automatic text completion.
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    public static let disableTextCompletion = TextViewOptions(rawValue: 1 << 8)
}
