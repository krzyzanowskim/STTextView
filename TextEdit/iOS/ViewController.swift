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
        textView.text = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
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
            ],
            range: NSRange(location: 0, length: 20)
        )
    }

    @objc func toggleTextWrapMode(_ sender: Any?) {
        textView.widthTracksTextView.toggle()
    }

}
