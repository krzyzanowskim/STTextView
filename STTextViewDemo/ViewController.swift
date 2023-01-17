//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import STTextView
import SwiftUI

final class ViewController: NSViewController {
    private var textView: STTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true

        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = 1.1
        paragraph.defaultTabInterval = 28 // default

        textView.defaultParagraphStyle = paragraph
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .textColor
        textView.string = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)

        // Line numbers
        let rulerView = STLineNumberRulerView(textView: textView)
        // Configure the ruler view
        rulerView.drawHighlightedRuler = true
        rulerView.highlightLineNumberColor = .textColor

        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = true

        textView.addAttributes([.foregroundColor: NSColor.systemBlue], range: NSRange(location: 0, length: 1))
        textView.addAttributes([.foregroundColor: NSColor.systemRed], range: NSRange(location: 2, length: 10))
        textView.addAttributes([.foregroundColor: NSColor.controlAccentColor, .font: NSFont.boldSystemFont(ofSize: 14)], range: NSRange(location: 18, length: 4))

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

        let lineAnnotation1 = MyLineAnnotation(
            message: "That's the goal",
            location: textView.textLayoutManager.location(textView.textLayoutManager.documentRange.location, offsetBy: 22)!
        )
        textView.addAnnotation(lineAnnotation1)

        let lineAnnotation2 = MyLineAnnotation(
            message: "Fix It!",
            location: textView.textLayoutManager.location(textView.textLayoutManager.documentRange.location, offsetBy: 1550)!
        )
        textView.addAnnotation(lineAnnotation2)
    }

    @IBAction func toggleTextWrapMode(_ sender: Any?) {
        textView.widthTracksTextView.toggle()
    }

    @objc func removeAnnotation(_ annotationView: STAnnotationLabelView) {
        textView.removeAnnotation(annotationView.annotation)
    }

}

class MyLineAnnotation: STLineAnnotation {
    let message: String

    init(message: String, location: NSTextLocation) {
        self.message = message
        super.init(location: location)
    }
}

extension ViewController: STTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        //
    }

    func textView(_ textView: STTextView, viewForLineAnnotation lineAnnotation: STLineAnnotation, textLineFragment: NSTextLineFragment) -> NSView? {
        guard let myLineAnnotation = lineAnnotation as? MyLineAnnotation else {
            return nil
        }

        let messageFont = NSFont.preferredFont(forTextStyle: .body).withSize(textView.font!.pointSize)

        let decorationView = STAnnotationLabelView(
            annotation: myLineAnnotation,
            label: AnnotationLabelView(
                message: myLineAnnotation.message,
                action: {
                    textView.removeAnnotation($0)
                },
                lineAnnotation: lineAnnotation
            )
            .font(Font(messageFont))
        )

        // Position
        
        let segmentFrame = textView.textLayoutManager.textSelectionSegmentFrame(at: lineAnnotation.location, type: .standard)!
        let annotationHeight = min(textLineFragment.typographicBounds.height, textView.font?.boundingRectForFont.height ?? 24)

        decorationView.frame = CGRect(
            x: segmentFrame.origin.x,
            y: segmentFrame.origin.y + (segmentFrame.height - annotationHeight),
            width: textView.bounds.width - segmentFrame.maxX,
            height: annotationHeight
        )
        return decorationView
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

private struct AnnotationLabelView: View {
    let message: String
    let action: (STLineAnnotation) -> Void
    let lineAnnotation: STLineAnnotation

    var body: some View {
        Label {
            Text(message)
        } icon: {
            Button {
                action(lineAnnotation)
            } label: {
                ZStack {
                    // the way it draws bothers me
                    // https://twitter.com/krzyzanowskim/status/1527723492002643969
                    Image(systemName: "octagon")
                        .symbolVariant(.fill)
                        .foregroundStyle(.red)

                    Image(systemName: "xmark.octagon")
                        .foregroundStyle(.white)
                }
                .shadow(radius: 1)
            }
            .buttonStyle(.plain)
        }
        .background(Color.yellow)
        .clipShape(RoundedRectangle(cornerRadius:4))
    }
}


private extension NSColor {

    func lighter(withLevel value: CGFloat = 0.3) -> NSColor {
        guard let color = usingColorSpace(.deviceRGB) else {
            return self
        }

        return NSColor(
            hue: color.hueComponent,
            saturation: max(color.saturationComponent - value, 0.0),
            brightness: color.brightnessComponent,
            alpha: color.alphaComponent)
    }
}
