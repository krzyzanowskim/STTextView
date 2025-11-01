//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

// Gutter line number cells container
final class STGutterMarkerContainerView: NSView {

    public override func makeBackingLayer() -> CALayer {
        CATiledLayer()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        clipsToBounds = true
    }

    override var isFlipped: Bool {
        true
    }

    override var isOpaque: Bool {
        false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
