//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

/// A data source that provides custom views for the gutter area of a text view.
///
/// Implement this protocol to supply one `NSView` per visible line in the
/// custom gutter. The data source is queried during layout for each line
/// that is currently in the viewport.
///
/// Use together with ``STTextView/customGutterWidth`` to reserve horizontal
/// space for the gutter area.
public protocol STGutterLineViewDataSource: AnyObject {

    /// Returns the view to display in the custom gutter for the given line.
    ///
    /// - Parameters:
    ///   - textView: The text view requesting the view.
    ///   - lineNumber: The 1-based line number.
    ///   - content: The plain-text content of the line (trailing newline stripped).
    /// - Returns: An `NSView` to be positioned in the gutter alongside the line.
    func textView(_ textView: STTextView, viewForGutterLine lineNumber: Int, content: String) -> NSView
}
