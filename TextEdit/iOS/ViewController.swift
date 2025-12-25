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
        textView.isHorizontallyResizable = false
        textView.highlightSelectedLine = true
        textView.textDelegate = self

        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = 1.2
        textView.defaultParagraphStyle = paragraph
        textView.alwaysBounceVertical = true

        textView.font = UIFont.monospacedSystemFont(ofSize: 0, weight: .regular)
        textView.text = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        textView.showsLineNumbers = true
        textView.showsInvisibleCharacters = false
        textView.gutterView?.areMarkersEnabled = true
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
            var currentRange = str.startIndex ..< str.endIndex
            while let ocurrenceRange = str.range(of: "STTextView", range: currentRange) {
                textView.addAttributes([.link: URL(string: "https://swift.best")! as NSURL], range: NSRange(ocurrenceRange, in: str))
                currentRange = ocurrenceRange.upperBound ..< currentRange.upperBound
            }
        }

        //  Insert attachment image using NSTextAttachmentViewProvider
        do {
            let attachment = MyTextAttachment()
            let attachmentString = NSAttributedString(attachment: attachment)
            textView.insertText(attachmentString, replacementRange: NSRange(location: 30, length: 0))
        }

    }

    @objc func toggleTextWrapMode(_: Any?) {
        textView.isHorizontallyResizable.toggle()
    }

    @IBAction func toggleInvisibles(_: Any?) {
        textView.showsInvisibleCharacters.toggle()
    }

    @IBAction func toggleRuler(_: Any?) {
        textView.showsLineNumbers.toggle()
    }

}

extension ViewController: STTextViewDelegate {

    func textViewWillChangeText(_: Notification) {}

    func textViewDidChangeText(_: Notification) {}

    func textViewDidChangeSelection(_: Notification) {}

    func textView(_: STTextView, shouldChangeTextIn _: NSTextRange, replacementString _: String?) -> Bool {
        true
    }

    func textView(_: STTextView, willChangeTextIn _: NSTextRange, replacementString _: String) {}

    func textView(_: STTextView, didChangeTextIn _: NSTextRange, replacementString _: String) {}

    func textView(_: STTextView, clickedOnLink _: Any, at _: any NSTextLocation) -> Bool {
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
        for parentView: UIView?,
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
