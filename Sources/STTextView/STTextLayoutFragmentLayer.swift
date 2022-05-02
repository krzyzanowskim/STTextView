//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import CoreGraphics

final class STTextLayoutFragmentLayer: STCALayer {
    private let layoutFragment: NSTextLayoutFragment

    init(layoutFragment: NSTextLayoutFragment) {
        self.layoutFragment = layoutFragment
        super.init(frame: .zero)
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(layer: Any) {
        if let myself = layer as? Self {
            layoutFragment = myself.layoutFragment
        } else {
            fatalError("Unexpected use")
        }
        super.init(layer: layer)
    }

    override func draw(in ctx: CGContext) {
        layoutFragment.draw(at: .zero, in: ctx)
    }
}
