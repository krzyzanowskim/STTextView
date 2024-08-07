//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// A common public interface for TextView
package protocol STTextViewProtocol {
    associatedtype RulerView
    associatedtype Color
    associatedtype Font
    associatedtype Delegate

    static var didChangeSelectionNotification: NSNotification.Name { get }
    static var textWillChangeNotification: NSNotification.Name { get }
    static var textDidChangeNotification: NSNotification.Name { get }

    var textLayoutManager: NSTextLayoutManager { get }
    var textContentManager: NSTextContentManager { get }
    var textContainer: NSTextContainer { get set }
    var widthTracksTextView: Bool { get set }
    var isHorizontallyResizable: Bool { get set }
    var heightTracksTextView: Bool { get set }
    var isVerticallyResizable: Bool { get set }
    var highlightSelectedLine: Bool { get set }
    var showLineNumbers: Bool { get set }
    var selectedLineHighlightColor: Color { get set}
    var font: Font? { get set }
    var textColor: Color? { get set }
    var text: String? { get set }
    var attributedText: NSAttributedString? { get set }
    var isEditable: Bool { get set }
    var isSelectable: Bool { get set }
    var defaultParagraphStyle: NSParagraphStyle? { get set }
    var typingAttributes: [NSAttributedString.Key: Any] { get set }
    var gutterView: RulerView? { get }
    var allowsUndo: Bool { get set }

    var textDelegate: Delegate? { get set }

    func toggleRuler(_ sender: Any?)
    var isRulerVisible: Bool { get set }

    func setSelectedTextRange(_ textRange: NSTextRange)

    func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool)
    func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool)

    func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool)
    func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool)

    func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange, updateLayout: Bool)
    func removeAttribute(_ attribute: NSAttributedString.Key, range: NSTextRange, updateLayout: Bool)

    func shouldChangeText(in affectedTextRange: NSTextRange, replacementString: String?) -> Bool
    func replaceCharacters(in range: NSTextRange, with string: String)
    func insertText(_ string: Any, replacementRange: NSRange)
}
