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
        textView.gutterView?.areMarkersEnabled = true
        textView.gutterView?.drawSeparator = true

        // Plugins
        // textView.addPlugin(DummyPlugin())

        view.addSubview(scrollView)

        // With fullSizeContentView enabled, constrain to safe area to avoid titlebar overlap
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // Add attributes

        // add link to occurences of STTextView
        do {
            let str = textView.text!
            var currentRange = str.startIndex ..< str.endIndex
            while let ocurrenceRange = str.range(of: "STTextView", range: currentRange) {
                textView.addAttributes([.link: URL(string: "https://swift.best")! as NSURL], range: NSRange(ocurrenceRange, in: str))
                currentRange = ocurrenceRange.upperBound ..< currentRange.upperBound
            }
        }

        do {
            let str = textView.text!
            var currentRange = str.startIndex ..< str.endIndex
            while let ocurrenceRange = str.range(of: "vim", range: currentRange) {
                textView.addAttributes([.cursor: NSCursor.operationNotAllowed], range: NSRange(ocurrenceRange, in: str))
                currentRange = ocurrenceRange.upperBound ..< currentRange.upperBound
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

        // Insert interactive button attachment
        do {
            let buttonAttachment = InteractiveButtonAttachment()
            let attachmentString = NSAttributedString(attachment: buttonAttachment)
            textView.insertText(attachmentString, replacementRange: NSRange(location: 60, length: 0))
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

    private var completionTask: Task<Void, Never>?

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
                    let symbol = if let firstCharacter = word.first, firstCharacter.isASCII, firstCharacter.isLetter {
                        "\(word.first!.lowercased()).square"
                    } else {
                        "note.text"
                    }

                    return Completion.Item(id: UUID().uuidString, label: word.localizedCapitalized, symbolName: symbol, insertText: word)
                }
        }
    }
}

// MARK: STTextViewDelegate

extension ViewController: STTextViewDelegate {

    func textView(_: STTextView, didChangeTextIn _: NSTextRange, replacementString _: String) {
        // Continous completion update disabled due to bad performance for large strings
        // updateCompletionsInBackground()
    }

    func textView(_ textView: STTextView, clickedOnAttachment attachment: NSTextAttachment, at _: any NSTextLocation) -> Bool {
        print("Clicked on attachment: \(attachment)")
        print("Selected range: \(textView.selectedRange())")

        if attachment is InteractiveButtonAttachment {
            // Handle button click - this now works for both text-based and view-based clicks
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
        // Allow interaction with all attachments
        return true
    }

    // Completion
    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) async -> [any STCompletionItem]? {

        // fake delay
        // try? await Task.sleep(nanoseconds: UInt64.random(in: 0...1) * 1_000_000_000)

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
        for _: [NSAttributedString.Key: Any],
        location _: any NSTextLocation,
        textContainer _: NSTextContainer?,
        proposedLineFragment _: CGRect,
        position _: CGPoint
    )
        -> CGRect {
        self.view?.bounds ?? .zero
    }
}

private class MyTextAttachment: NSTextAttachment {
    override func viewProvider(
        for parentView: NSView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    )
        -> NSTextAttachmentViewProvider? {
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

// MARK: Interactive Button Attachment

private class InteractiveButtonAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        let button = NSButton(title: "Click Me!", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        // Note: Target and action will be set automatically by the attachment interaction bridge
        self.view = button
    }

    override func attachmentBounds(
        for _: [NSAttributedString.Key: Any],
        location _: any NSTextLocation,
        textContainer _: NSTextContainer?,
        proposedLineFragment _: CGRect,
        position _: CGPoint
    )
        -> CGRect {
        return self.view?.bounds ?? CGRect(x: 0, y: 0, width: 80, height: 24)
    }
}

private class InteractiveButtonAttachment: NSTextAttachment {
    override func viewProvider(
        for parentView: NSView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    )
        -> NSTextAttachmentViewProvider? {
        let viewProvider = InteractiveButtonAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
        viewProvider.tracksTextAttachmentViewBounds = true
        return viewProvider
    }
}
