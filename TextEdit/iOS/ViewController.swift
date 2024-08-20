//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextView

class ViewController: UIViewController {

    @ViewLoading
    private var textView: STTextView

    override func viewDidLoad() {
        super.viewDidLoad()

        let textView = STTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.highlightSelectedLine = true
        textView.textDelegate = self

        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = 1.2

        textView.typingAttributes[.paragraphStyle] = paragraph
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.text = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        textView.showsLineNumbers = true
        textView.showsInvisibleCharacters = true
        textView.gutterView?.drawSeparator = true
        view.addSubview(textView)
        self.textView = textView

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Emphasize first line
        textView.addAttributes(
            [
                .foregroundColor: UIColor.tintColor,
                .font: UIFont.preferredFont(forTextStyle: .largeTitle)
            ],
            range: NSRange(location: 0, length: 20)
        )

        // add link to occurences of STTextView
        if let str = textView.text {
            var currentRange = str.startIndex..<str.endIndex
            while let ocurrenceRange = str.range(of: "STTextView", range: currentRange) {
                textView.addAttributes([.link: URL(string: "https://swift.best")! as NSURL], range: NSRange(ocurrenceRange, in: str))
                currentRange = ocurrenceRange.upperBound..<currentRange.upperBound
            }
        }

        //  Insert attachment image using NSTextAttachmentViewProvider
        do {
             let attachment = MyTextAttachment()
             let attachmentString = NSAttributedString(attachment: attachment)
             textView.insertText(attachmentString, replacementRange: NSRange(location: 30, length: 0))
        }

    }

    @objc func toggleTextWrapMode(_ sender: Any?) {
        textView.widthTracksTextView.toggle()
    }

    @IBAction func toggleInvisibles(_ sender: Any?) {
        textView.showsInvisibleCharacters.toggle()
    }

    @IBAction func toggleRuler(_ sender: Any?) {
        textView.showsLineNumbers.toggle()
    }

}

extension ViewController: STTextViewDelegate {

    func textViewWillChangeText(_ notification: Notification) {

    }

    func textViewDidChangeText(_ notification: Notification) {

    }

    func textViewDidChangeSelection(_ notification: Notification) {

    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        true
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {

    }

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {

    }

    func textView(_ textView: STTextView, clickedOnLink link: Any, at location: any NSTextLocation) -> Bool {
        false
    }

}

// MARK: TextAttachment provider

private class MyTextAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        // super.loadView()
        let image = UIImage(systemName: "figure.walk")!
        let imageView = UIImageView(image: image)
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [UIColor.label])
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
        for parentView: UIView?,
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
