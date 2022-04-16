//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

final class STTextFinderClient: NSObject, NSTextFinderClient {

    weak var textView: STTextView?

    // cached value
    private var stringCount: Int = 0

    private var textContentManager: NSTextContentManager? {
        textView?.textContentStorage
    }

    var string: String {
        let str = textView?.string ?? ""
        stringCount = str.count
        return str
    }

    func stringLength() -> Int {
        stringCount
    }

    var isSelectable: Bool {
        textView?.isSelectable ?? false
    }

    public var allowsMultipleSelection: Bool {
        false
    }

    func replaceCharacters(in range: NSRange, with string: String) {
        guard let textContentManager = textContentManager,
              let textRange = NSTextRange(range, in: textContentManager)
        else {
            return
        }

        textView?.willChangeText()
        textView?.replaceCharacters(in: textRange, with: string)
    }

    func didReplaceCharacters() {
        textView?.didChangeText()
    }

    public var firstSelectedRange: NSRange {
        guard let firstTextSelectionRange = textView?.textLayoutManager.textSelections.first?.textRanges.first,
              let textContentManager = textContentManager else {
            return NSRange()
        }

        return NSRange(firstTextSelectionRange, in: textContentManager)
    }

    public var selectedRanges: [NSValue] {
        set {
            guard let textContentManager = textContentManager,
                  let textLayoutManager = textView?.textLayoutManager as? STTextLayoutManager else {
                assertionFailure()
                return
            }

            let textRanges = newValue.map(\.rangeValue).compactMap {
                NSTextRange($0, in: textContentManager)
            }

            textLayoutManager.textSelections = [NSTextSelection(textRanges, affinity: .downstream, granularity: .character)]
            textView?.updateSelectionHighlights()
        }

        get {
            guard let textContentManager = textContentManager,
                  let textLayoutManager = textView?.textLayoutManager,
                  !textLayoutManager.textSelections.isEmpty
            else {
                return []
            }

            return textLayoutManager.textSelections.flatMap(\.textRanges).compactMap({ NSRange($0, in: textContentManager) }).map({ NSValue(range: $0) })
        }
    }

    var isEditable: Bool {
        textView?.isEditable ?? false
    }

    func scrollRangeToVisible(_ range: NSRange) {
        guard let textContentManager = textContentManager,
              let textRange = NSTextRange(range, in: textContentManager)
        else {
            return
        }

        textView?.scrollToSelection(NSTextSelection(range: textRange, affinity: .downstream, granularity: .character))
    }

    var visibleCharacterRanges: [NSValue] {
        guard let viewportTextRange = textView?.textLayoutManager.textViewportLayoutController.viewportRange,
              let textContentManager = textContentManager else {
            return []
        }

        return [NSRange(viewportTextRange, in: textContentManager)].map({ NSValue(range: $0) })
    }

    func rects(forCharacterRange range: NSRange) -> [NSValue]? {
        guard let textContentManager = textContentManager,
              let textRange = NSTextRange(range, in: textContentManager)
        else {
            return nil
        }

        var rangeRects: [CGRect] = []
        textView?.textLayoutManager.enumerateTextSegments(in: textRange, type: .standard, options: .rangeNotRequired, using: { _, rect, _, _ in
            rangeRects.append(rect.pixelAligned)
            return true
        })

        return rangeRects.map({ NSValue(rect: $0) })
    }

    func contentView(at index: Int, effectiveCharacterRange outRange: NSRangePointer) -> NSView {
        outRange.pointee = NSRange(location: 0, length: stringLength())
        return textView!
    }

    func drawCharacters(in range: NSRange, forContentView view: NSView) {
        guard let textView = view as? STTextView,
              let textRange = NSTextRange(range, in: textView.textContentStorage),
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
