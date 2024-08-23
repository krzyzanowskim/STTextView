//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

@objcMembers
final class STTextFinderClient: NSObject, NSTextFinderClient {

    weak var textView: STTextView?

    var string: String {
        textView?.text ?? ""
    }

    func stringLength() -> Int {
        string.utf16.count
    }

    var isSelectable: Bool {
        textView?.isSelectable ?? false
    }

    var isEditable: Bool {
        textView?.isEditable ?? false
    }

    var allowsMultipleSelection: Bool {
        false
    }

    func shouldReplaceCharacters(inRanges ranges: [NSValue], with strings: [String]) -> Bool {
        guard let textView = textView,
              let textContentManager = textView.textLayoutManager.textContentManager
        else {
            return false
        }

        var result = true
        for (range, string) in zip(ranges.map(\.rangeValue), strings) {
            if let textRange = NSTextRange(range, in: textContentManager) {
                result = result && textView.shouldChangeText(in: textRange, replacementString: string)
            }
        }

        return result
    }

    func replaceCharacters(in range: NSRange, with string: String) {
        guard let textContentManager = textView?.textLayoutManager.textContentManager,
              let textRange = NSTextRange(range, in: textContentManager),
              let textView = textView
        else {
            return
        }

        if textView.shouldChangeText(in: textRange, replacementString: string) {
            let typingAttributes = textView.typingAttributes(at: textRange.location)
            let attributedString = NSAttributedString(string: string, attributes: typingAttributes)
            textView.replaceCharacters(in: textRange, with: attributedString, allowsTypingCoalescing: false)
        }
    }

    var firstSelectedRange: NSRange {
        guard let textLayoutManager = textView?.textLayoutManager,
            let firstTextSelectionRange = textLayoutManager.textSelections.first?.textRanges.first,
            let textContentManager = textLayoutManager.textContentManager
        else {
            return NSRange()
        }

        return NSRange(firstTextSelectionRange, in: textContentManager)
    }

    var selectedRanges: [NSValue] {
        set {
            guard let textLayoutManager = textView?.textLayoutManager,
                  let textContentManager = textLayoutManager.textContentManager
            else {
                assertionFailure()
                return
            }

            let textRanges = newValue.map(\.rangeValue).compactMap {
                NSTextRange($0, in: textContentManager)
            }

            textLayoutManager.textSelections = [NSTextSelection(textRanges, affinity: .downstream, granularity: .character)]
            textView?.updateSelectedRangeHighlight()
            textView?.layoutGutter()
            textView?.updateSelectedLineHighlight()
            textView?.updateTypingAttributes()
        }

        get {
            guard let textLayoutManager = textView?.textLayoutManager,
                  !textLayoutManager.textSelections.isEmpty,
                  let textContentManager = textLayoutManager.textContentManager
            else {
                return []
            }

            return textLayoutManager.textSelections
                .filter {
                    !$0.isTransient
                }
                .flatMap(\.textRanges)
                .compactMap {
                    NSRange($0, in: textContentManager)
                }.map(\.nsValue)
        }
    }

    func scrollRangeToVisible(_ range: NSRange) {
        guard let textView = textView,
              let textContentManager = textView.textLayoutManager.textContentManager,
              let textRange = NSTextRange(range, in: textContentManager)
        else {
            return
        }

        textView.scrollToVisible(textRange, type: .standard)
    }

    var visibleCharacterRanges: [NSValue] {
        guard let textLayoutManager = textView?.textLayoutManager,
              let viewportTextRange = textLayoutManager.textViewportLayoutController.viewportRange,
              let textContentManager = textLayoutManager.textContentManager
        else {
            return []
        }

        return [NSRange(viewportTextRange, in: textContentManager).nsValue]
    }

    func rects(forCharacterRange range: NSRange) -> [NSValue]? {
        guard let textContentManager = textView?.textLayoutManager.textContentManager,
              let textRange = NSTextRange(range, in: textContentManager)
        else {
            return nil
        }

        var rangeRects: [CGRect] = []
        textView?.textLayoutManager.enumerateTextSegments(in: textRange, type: .standard, options: .rangeNotRequired, using: { _, rect, _, _ in
            rangeRects.append(rect)
            return true
        })

        return rangeRects.map { NSValue(rect: $0) }
    }

    func contentView(at index: Int, effectiveCharacterRange outRange: NSRangePointer) -> NSView {
        guard let textView = textView,
              let textContentManager = textView.textLayoutManager.textContentManager
        else {
            assertionFailure()
            return textView!
        }

        outRange.pointee = NSRange(textContentManager.documentRange, in: textContentManager)
        return textView
    }

    func drawCharacters(in range: NSRange, forContentView view: NSView) {
        guard let textView = view as? STTextView, textView == self.textView,
              let textContentManager = textView.textLayoutManager.textContentManager,
              let textRange = NSTextRange(range, in: textContentManager),
              let context = NSGraphicsContext.current?.cgContext
        else {
            assertionFailure()
            return
        }

        if let layoutFragment = textView.textLayoutManager.textLayoutFragment(for: textRange.location) {
            layoutFragment.draw(at: layoutFragment.layoutFragmentFrame.pixelAligned.origin, in: context)
        }
    }

}
