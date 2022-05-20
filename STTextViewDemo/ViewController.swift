//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import STTextView

final class ViewController: NSViewController {
    private var textView: STTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true

        // Line numbers
        scrollView.verticalRulerView = STLineNumberRulerView(textView: textView, scrollView: scrollView)
        scrollView.rulersVisible = true

        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = 1.1
        paragraph.defaultTabInterval = 28 // default

        textView.defaultParagraphStyle = paragraph
        textView.font = NSFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        textView.textColor = .textColor
        textView.string = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        
        // When first character font size is big enough, the text segment frame for first line is incorrect
        // see README for bugs
        textView.addAttributes([.font: NSFont.systemFont(ofSize: 50)], range: NSRange(location: 1, length: 1))

        textView.addAttributes([.foregroundColor: NSColor.systemRed], range: NSRange(location: 6, length: 5))
        textView.addAttributes([.foregroundColor: NSColor.systemMint], range: NSRange(location: 12, length: 5))
        textView.widthTracksTextView = false // wrap
        textView.highlightSelectedLine = true
        textView.textFinder.isIncrementalSearchingEnabled = true
        textView.textFinder.incrementalSearchingShouldDimContentView = true
        textView.delegate = self

        scrollView.documentView = textView

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let lineAnnotation = STTextView.LineAnnotation(
            location: textView.textLayoutManager.location(textView.textLayoutManager.documentRange.location, offsetBy: 10)!
        )
        textView.addAnnotation(lineAnnotation)
    }

    @IBAction func toggleTextWrapMode(_ sender: Any?) {
        textView.widthTracksTextView.toggle()
    }

}

extension ViewController: STTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        //
    }

    func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STTextView.LineAnnotation, textLineFragment: NSTextLineFragment) -> NSView? {
        let decorationView = AnnotationView()
        decorationView.wantsLayer = true
        decorationView.layer?.backgroundColor = NSColor.systemRed.cgColor

        let segmentFrame = textView.textLayoutManager.textSelectionSegmentFrame(at: lineAnnotation.location, type: .standard)!
        decorationView.frame = CGRect(
            x: segmentFrame.origin.x,
            y: segmentFrame.origin.y,
            width: textView.bounds.width - segmentFrame.maxX,
            height: textLineFragment.typographicBounds.height
        )
        return decorationView
    }
}

class AnnotationView: NSView {
    override var isFlipped: Bool {
        true
    }
}
