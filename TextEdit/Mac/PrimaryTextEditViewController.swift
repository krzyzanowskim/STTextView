//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextView
import SwiftUI

// import DummyPlugin

final class PrimaryTextEditViewController: NSViewController {
    private var textView: STTextView!
    private var completionTask: Task<Void, Never>?
    private var completions: [Completion.Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true

        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = 1.2
        textView.defaultParagraphStyle = paragraph

        textView.font = NSFont.monospacedSystemFont(ofSize: 0, weight: .regular)
        textView.text = Self.defaultText
        textView.isHorizontallyResizable = false // wrap
        textView.highlightSelectedLine = true
        textView.isIncrementalSearchingEnabled = true
        textView.showsInvisibleCharacters = false
        textView.textDelegate = self
        textView.showsLineNumbers = true
        textView.gutterView?.areMarkersEnabled = true
        textView.gutterView?.drawSeparator = true

        // Plugins
        // textView.addPlugin(DummyPlugin())

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        applySampleDecorations()
        updateCompletionsInBackground()
    }

    @IBAction func toggleTextWrapMode(_: Any?) {
        textView.isHorizontallyResizable.toggle()
    }

    @IBAction func toggleInvisibles(_: Any?) {
        textView.showsInvisibleCharacters.toggle()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        completionTask?.cancel()
    }

    private func updateCompletionsInBackground() {
        completionTask?.cancel()
        completionTask = Task(priority: .background) {
            var arr: Set<String> = []

            for await word in Tokenizer.words(textView.text ?? "") where !Task.isCancelled {
                arr.insert(word.string)
            }

            if Task.isCancelled {
                return
            }

            self.completions = arr
                .filter { $0.count > 2 }
                .sorted { lhs, rhs in
                    lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                }
                .map { word in
                    let symbol = if let firstCharacter = word.first, firstCharacter.isASCII, firstCharacter.isLetter {
                        "\(word.first!.lowercased()).square"
                    } else {
                        "note.text"
                    }

                    return Completion.Item(id: UUID().uuidString, label: word.localizedCapitalized, symbolName: symbol, insertText: word)
                }
        }
    }

    private func applySampleDecorations() {
        guard let text = textView.text, !text.isEmpty else {
            return
        }

        do {
            var currentRange = text.startIndex ..< text.endIndex
            while let occurrenceRange = text.range(of: "STTextView", range: currentRange) {
                textView.addAttributes([.link: URL(string: "https://swift.best")! as NSURL], range: NSRange(occurrenceRange, in: text))
                currentRange = occurrenceRange.upperBound ..< currentRange.upperBound
            }
        }

        do {
            var currentRange = text.startIndex ..< text.endIndex
            while let occurrenceRange = text.range(of: "vim", range: currentRange) {
                textView.addAttributes([.cursor: NSCursor.operationNotAllowed], range: NSRange(occurrenceRange, in: text))
                currentRange = occurrenceRange.upperBound ..< currentRange.upperBound
            }
        }

        do {
            let attachment = MyTextAttachment()
            let attachmentString = NSAttributedString(attachment: attachment)
            textView.insertText(attachmentString, replacementRange: NSRange(location: 30, length: 0))
        }

        do {
            let buttonAttachment = InteractiveButtonAttachment()
            let attachmentString = NSAttributedString(attachment: buttonAttachment)
            textView.insertText(attachmentString, replacementRange: NSRange(location: 60, length: 0))
        }

        if let firstLine = text.linesRanges().first {
            textView.addAttributes(
                [
                    .foregroundColor: NSColor.controlAccentColor,
                    .font: NSFont.preferredFont(forTextStyle: .largeTitle)
                ],
                range: NSRange(firstLine, in: text)
            )
        }
    }
}

private extension PrimaryTextEditViewController {
    static let defaultText = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
}

extension PrimaryTextEditViewController: STTextViewDelegate {
    func textView(_: STTextView, didChangeTextIn _: NSTextRange, replacementString _: String) {
        // Continous completion update disabled due to bad performance for large strings
    }

    func textView(_ textView: STTextView, clickedOnAttachment attachment: NSTextAttachment, at _: any NSTextLocation) -> Bool {
        print("Clicked on attachment: \(attachment)")
        print("Selected range: \(textView.selectedRange())")

        if attachment is InteractiveButtonAttachment {
            let alert = NSAlert()
            alert.messageText = "Button Clicked!"
            alert.informativeText = "The interactive button attachment was clicked and selected.\nThis works for both clicking the attachment character in text and clicking the button view directly!"
            alert.runModal()
            return true
        } else if attachment is MyTextAttachment {
            let alert = NSAlert()
            alert.messageText = "Image Attachment Clicked!"
            alert.informativeText = "You clicked on the walking figure attachment and it's now selected."
            alert.runModal()
            return true
        }
        return false
    }

    func textView(_: STTextView, shouldAllowInteractionWith _: NSTextAttachment, at _: any NSTextLocation) -> Bool {
        true
    }

    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) async -> [any STCompletionItem]? {
        var word: String?
        textView.textLayoutManager.enumerateSubstrings(from: location, options: [.byWords, .reverse]) { substring, _, _, stop in
            word = substring
            stop.pointee = true
        }

        if let word {
            return completions.filter { item in
                if Task.isCancelled {
                    return false
                }
                return item.insertText.hasPrefix(word.localizedLowercase)
            }
        }

        return nil
    }

    func textView(_ textView: STTextView, insertCompletionItem item: any STCompletionItem) {
        guard let completionItem = item as? Completion.Item else {
            fatalError()
        }

        textView.insertText(completionItem.insertText)
    }
}

private extension StringProtocol {
    func linesRanges() -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        let stringRange = startIndex ..< endIndex
        var currentIndex = startIndex
        while currentIndex < stringRange.upperBound {
            let lineRange = lineRange(for: currentIndex ..< currentIndex)
            ranges.append(lineRange)
            if !stringRange.overlaps(lineRange) {
                break
            }
            currentIndex = lineRange.upperBound
        }
        return ranges
    }
}
