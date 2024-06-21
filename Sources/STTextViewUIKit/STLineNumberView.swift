//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

@objc protocol STLineNumberViewDelegate: AnyObject {
    func lineNumberViewTextLayoutManager(_ lineNumberView: STLineNumberView) -> NSTextLayoutManager
}

@objc open class STLineNumberView: UIView {
    weak var delegate: STLineNumberViewDelegate?

    /// A Boolean indicating whether to draw a separator or not.
    @Invalidating(.display)
    open var drawSeparator: Bool = true

    // @Invalidating(.display)
    // open var highlightSelectedLine: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
}
