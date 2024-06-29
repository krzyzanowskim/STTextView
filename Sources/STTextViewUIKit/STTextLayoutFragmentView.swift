//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import CoreGraphics
import STTextKitPlus
import CoreTextSwift

final class STTextLayoutFragmentView: UIView {
    private let layoutFragment: NSTextLayoutFragment

    init(layoutFragment: NSTextLayoutFragment, frame: CGRect) {
        self.layoutFragment = layoutFragment
        super.init(frame: frame)
        layoutGlyphLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayerContentScale()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateLayerContentScale()
    }

    private func updateLayerContentScale() {
        let newScale = window?.screen.scale ?? UIScreen.main.scale
        layer.contentsScale = newScale
        layer.sublayers?.forEach { $0.contentsScale = newScale }
    }

    private func layoutGlyphLayers() {
        // layout each character on separate layer, so it can be animable
        for textLineFragment in layoutFragment.textLineFragments {
            let lineAttributedString = textLineFragment.attributedString.attributedSubstring(from: textLineFragment.characterRange)

            for run in lineAttributedString.line().glyphRuns() {
                let glyphs = run.glyphs()
                let glyphPositions = run.glyphPositions()
                let boundingRects = run.font.boundingRects(of: glyphs)
                for idx in 0..<run.glyphsCount {
                    let glyph = glyphs[idx]
                    let glyphPosition = glyphPositions[idx]
                    let boundingRect = boundingRects[idx]
                    let glyphLayer = GlyphLayer(font: run.font, color: run.attributes[.foregroundColor] as? UIColor ?? UIColor.label, glyph: glyph)

                    glyphLayer.frame = CGRect(
                        x: textLineFragment.typographicBounds.origin.x + glyphPosition.x,
                        y: textLineFragment.typographicBounds.origin.y + glyphPosition.y,
                        width: boundingRect.maxX,
                        height: textLineFragment.typographicBounds.height
                    )

                    glyphLayer.bounds.origin.y -= textLineFragment.typographicBounds.height - textLineFragment.glyphOrigin.y

                    glyphLayer.setNeedsDisplay()
                    layer.addSublayer(glyphLayer)
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // TODO: layoutAttachmentView()
    }
}

private class GlyphLayer: CALayer {
    let color: UIColor
    let font: CTFont
    let glyph: CGGlyph

    init(font: CTFont, color: UIColor, glyph: CGGlyph) {
        self.font = font
        self.glyph = glyph
        self.color = color
        super.init()

        isGeometryFlipped = true
    }

    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)

        ctx.setFillColor(color.cgColor)
        font.draw(glyphs: [glyph], at: [.zero], in: ctx)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
