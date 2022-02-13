//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import CoreGraphics

final class TextLayoutFragmentView: NSView {
    private let layoutFragment: NSTextLayoutFragment

    init(layoutFragment: NSTextLayoutFragment) {
        self.layoutFragment = layoutFragment
        super.init(frame: .zero)
        updateGeometry()
        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        layoutFragment.draw(at: .zero, in: context)
        context.restoreGState()
    }

    func updateGeometry() {
        frame = layoutFragment.layoutFragmentFrame
    }
}
