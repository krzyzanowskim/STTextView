//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import CoreGraphics
import STTextKitPlus

final class STTextLayoutFragmentView: UIView {
    private let layoutFragment: NSTextLayoutFragment

    init(layoutFragment: NSTextLayoutFragment, frame: CGRect) {
        self.layoutFragment = layoutFragment
        super.init(frame: frame)
        isOpaque = false
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        super.draw(rect)
        layoutFragment.draw(at: .zero, in: context)
        // TODO: drawSpellCheckerAttributes(dirtyRect, in: context)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // TODO: layoutAttachmentView()
    }
}
