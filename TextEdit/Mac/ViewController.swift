//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextView
import SwiftUI

// import DummyPlugin

final class ViewController: NSViewController {
    private var textView: STTextView!

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
        textView.text = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        textView.isHorizontallyResizable = false // wrap
        textView.highlightSelectedLine = true
        textView.isIncrementalSearchingEnabled = true
        textView.showsInvisibleCharacters = false
        textView.textDelegate = self
        textView.showsLineNumbers = true
        textView.gutterView?.drawSeparator = true

        // Plugins
        // textView.addPlugin(DummyPlugin())

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add attributes

        // add link to occurences of STTextView
        do {
            let str = textView.text!
            var currentRange = str.startIndex..<str.endIndex
            while let ocurrenceRange = str.range(of: "STTextView", range: currentRange) {
                textView.addAttributes([.link: URL(string: "https://swift.best")! as NSURL], range: NSRange(ocurrenceRange, in: str))
                currentRange = ocurrenceRange.upperBound..<currentRange.upperBound
            }
        }

        do {
            let str = textView.text!
            var currentRange = str.startIndex..<str.endIndex
            while let ocurrenceRange = str.range(of: "vim", range: currentRange) {
                textView.addAttributes([.cursor: NSCursor.operationNotAllowed], range: NSRange(ocurrenceRange, in: str))
                currentRange = ocurrenceRange.upperBound..<currentRange.upperBound
            }
        }

        // Insert attachment image using NSTextAttachmentCell
        //
        // do {
        //     let attachment = NSTextAttachment()
        //     let img = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil)
        //     let cell = NSTextAttachmentCell(imageCell: img)
        //     attachment.attachmentCell = cell
        //     let attachmentString = NSAttributedString(attachment: attachment)
        //     textView.insertText(attachmentString, replacementRange: NSRange(location: 20, length: 0))
        // }

        //  Insert attachment image using NSTextAttachmentViewProvider
        do {
            let attachment = MyTextAttachment()
            let attachmentString = NSAttributedString(attachment: attachment)
            textView.insertText(attachmentString, replacementRange: NSRange(location: 30, length: 0))
        }


        // Emphasize first line
        textView.addAttributes(
            [
                .foregroundColor: NSColor.controlAccentColor,
                .font: NSFont.preferredFont(forTextStyle: .largeTitle)
            ],
            range: NSRange(textView.text!.linesRanges().first!, in: textView.text!)
        )

        updateCompletionsInBackground()
    }

    @IBAction func toggleTextWrapMode(_ sender: Any?) {
        textView.isHorizontallyResizable.toggle()
    }

    @IBAction func toggleInvisibles(_ sender: Any?) {
        textView.showsInvisibleCharacters.toggle()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        completionTask?.cancel()
    }

    private var completionTask: Task<(), Never>?

    /// Update completion list with words
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
                .filter {
                    $0.count > 2
                }
                .sorted { lhs, rhs in
                    lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                }
                .map { word in
                    let symbol: String
                    if let firstCharacter = word.first, firstCharacter.isASCII, firstCharacter.isLetter {
                        symbol = "\(word.first!.lowercased()).square"
                    } else {
                        symbol = "note.text"
                    }

                    return Completion.Item(id: UUID().uuidString, label: word.localizedCapitalized, symbolName: symbol, insertText: word)
                }
        }
    }
}

// MARK: STTextViewDelegate

extension ViewController: STTextViewDelegate {

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        // Continous completion update disabled due to bad performance for large strings
        // updateCompletionsInBackground()
    }

    // Completion

    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) -> [any STCompletionItem]? {

        var word: String?
        textView.textLayoutManager.enumerateSubstrings(from: location, options: [.byWords, .reverse]) { substring, substringRange, enclosingRange, stop in
            word = substring
            stop.pointee = true
        }

        if let word {
            return completions.filter { item in
                item.insertText.hasPrefix(word.localizedLowercase)
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
        let stringRange = startIndex..<endIndex
        var currentIndex = startIndex
        while currentIndex < stringRange.upperBound {
            let lineRange = lineRange(for: currentIndex..<currentIndex)
            ranges.append(lineRange)
            if !stringRange.overlaps(lineRange) {
                break
            }
            currentIndex = lineRange.upperBound
        }
        return ranges
    }
}

// MARK: TextAttachment provider

private class MyTextAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        // super.loadView()
        let image = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil)!
        let imageView = NSImageView(image: image)
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(paletteColors: [NSColor.labelColor])
        self.view = imageView
    }

    override func attachmentBounds(
        for attributes: [NSAttributedString.Key : Any],
        location: any NSTextLocation,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        self.view?.bounds ?? .zero
    }
}

private class MyTextAttachment: NSTextAttachment {
    override func viewProvider(
        for parentView: NSView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        let viewProvider = MyTextAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
        viewProvider.tracksTextAttachmentViewBounds = true
        return viewProvider
    }
}
