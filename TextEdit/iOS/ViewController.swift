//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import STTextView

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let textView = STTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        // textView.contentInsetAdjustmentBehavior = .always
        view.addSubview(textView)

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
                .font: UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize * 1.2, weight: .bold)
            ],
            range: NSRange(location: 0, length: 20)
        )
    }

}
