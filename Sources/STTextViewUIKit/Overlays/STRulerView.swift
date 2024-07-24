//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

final class STRulerView: UIView {
    let lineNumberView: STLineNumberView

    override init(frame: CGRect) {
        lineNumberView = STLineNumberView(frame: frame)
        lineNumberView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.secondarySystemBackground

        addSubview(lineNumberView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
