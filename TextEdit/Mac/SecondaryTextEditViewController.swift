//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextView
import SwiftUI

final class SecondaryTextEditViewController: NSViewController {
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
        textView.text = ""
        textView.isHorizontallyResizable = false // wrap
        textView.highlightSelectedLine = true
        textView.isIncrementalSearchingEnabled = true
        textView.showsInvisibleCharacters = false
        textView.textDelegate = self
        textView.showsLineNumbers = true
        textView.gutterView?.areMarkersEnabled = true
        textView.gutterView?.drawSeparator = true

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

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
}

extension SecondaryTextEditViewController: STTextViewDelegate {
    func textView(_: STTextView, didChangeTextIn _: NSTextRange, replacementString _: String) {
        // Continous completion update disabled due to bad performance for large strings
    }

    func textView(_: STTextView, clickedOnAttachment _: NSTextAttachment, at _: any NSTextLocation) -> Bool {
        false
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
