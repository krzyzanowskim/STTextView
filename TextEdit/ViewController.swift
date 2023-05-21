//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import STTextView
import SwiftUI

final class ViewController: NSViewController {
    private var textView: STTextView!
    private var annotations: [LineAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true

        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = 1.2
        paragraph.defaultTabInterval = 28 // default

        textView.typingAttributes[.paragraphStyle] = paragraph
        textView.font = NSFont.monospacedSystemFont(ofSize: 0, weight: .regular)
        textView.string = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)

        textView.widthTracksTextView = false // wrap
        textView.highlightSelectedLine = true
        textView.textFinder.isIncrementalSearchingEnabled = true
        textView.textFinder.incrementalSearchingShouldDimContentView = true
        textView.delegate = self
        textView.dataSource = self

        scrollView.documentView = textView

        // Line numbers
        let rulerView = STLineNumberRulerView(textView: textView)
        rulerView.font = NSFont.monospacedSystemFont(ofSize: 0, weight: .regular)
        rulerView.allowsMarkers = true
        rulerView.highlightSelectedLine = true
        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = true

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add attributes

        // highlight occurence of STTextView
        do {
            var currentRange = textView.string.startIndex..<textView.string.endIndex
            while let ocurrenceRange = textView.string.range(of: "STTextView", range: currentRange) {
                textView.addAttributes([.foregroundColor: NSColor.controlAccentColor], range: NSRange(ocurrenceRange, in: textView.string))

                let characterLocationOffset = textView.string.distance(from: textView.string.startIndex, to: ocurrenceRange.upperBound)
                let annotation = try! LineAnnotation(
                    message: AttributedString(markdown: "**TODO**: todo _or_ not todo"),
                    location: textView.textLayoutManager.location(textView.textLayoutManager.documentRange.location, offsetBy: characterLocationOffset)!
                )
                annotations.append(annotation)

                currentRange = ocurrenceRange.upperBound..<currentRange.upperBound
            }
        }

        // Emphasize first line
        textView.addAttributes(
            [
                .foregroundColor: NSColor.controlAccentColor,
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize * 1.2, weight: .bold)
            ],
            range: NSRange(textView.string.linesRanges().first!, in: textView.string)
        )
    }

    @IBAction func toggleTextWrapMode(_ sender: Any?) {
        textView.widthTracksTextView.toggle()
    }

    @objc func removeAnnotation(_ annotation: STLineAnnotation) {
        annotations.removeAll(where: { $0 == annotation })
        textView.reloadData()
    }

}

// MARK: STTextViewDelegate

extension ViewController: STTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        //
    }

    // Completion

    func textView(_ textView: STTextView, completionItemsAtLocation location: NSTextLocation) -> [Any]? {
        [
            STCompletion.Item(id: UUID().uuidString, label: "One", insertText: "one"),
            STCompletion.Item(id: UUID().uuidString, label: "Two", insertText: "two"),
            STCompletion.Item(id: UUID().uuidString, label: "Three", insertText: "three")
        ]
    }

    func textView(_ textView: STTextView, insertCompletionItem item: Any) {
        textView.insertText((item as! STCompletion.Item).insertText)
    }
}

// MARK: STTextViewDataSource

extension ViewController: STTextViewDataSource {
    func textViewAnnotations(_ textView: STTextView) -> [STLineAnnotation] {
        annotations
    }

    func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STLineAnnotation, textLineFragment: NSTextLineFragment) -> NSView? {
        guard let myLineAnnotation = lineAnnotation as? LineAnnotation else {
            return nil
        }

        let messageFont = NSFont.preferredFont(forTextStyle: .body)

        let decorationView = STAnnotationLabelView(
            annotation: myLineAnnotation,
            label: AnnotationLabelView(
                message: myLineAnnotation.message,
                action: { [weak self] annotation in
                    self?.removeAnnotation(annotation)
                },
                lineAnnotation: lineAnnotation
            )
            .font(Font(messageFont))
        )

        // Position

        let segmentFrame = textView.textLayoutManager.textSelectionSegmentFrame(at: lineAnnotation.location, type: .standard)!
        let annotationHeight = min(textLineFragment.typographicBounds.height, textView.font?.boundingRectForFont.height ?? 24)

        decorationView.frame = CGRect(
            x: segmentFrame.maxX,
            y: segmentFrame.minY + (segmentFrame.height - annotationHeight),
            width: textView.bounds.width - segmentFrame.maxX,
            height: annotationHeight
        )
        return decorationView
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

