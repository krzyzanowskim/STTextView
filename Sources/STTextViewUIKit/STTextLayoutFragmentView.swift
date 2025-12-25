//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit
import CoreGraphics
import STTextKitPlus
#if USE_LAYERS_FOR_GLYPHS
    import CoreTextSwift
#endif

final class STTextLayoutFragmentView: UIView {
    private let layoutFragment: NSTextLayoutFragment
    private var layoutStateObservation: NSKeyValueObservation?

    init(layoutFragment: NSTextLayoutFragment, frame: CGRect) {
        self.layoutFragment = layoutFragment
        super.init(frame: frame)
        isOpaque = false

        layoutStateObservation = layoutFragment.observe(\.state, options: [.new, .initial]) { [weak self] layoutFragment, _ in
            if layoutFragment.state == .layoutAvailable {
                self?.layoutAttachmentView()
                self?.layoutStateObservation = nil
            }
        }
        #if USE_LAYERS_FOR_GLYPHS
            layoutGlyphLayers()
        #endif
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

    #if !USE_LAYERS_FOR_GLYPHS
        override func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }
            super.draw(rect)
            layoutFragment.draw(at: .zero, in: context)
            // TODO: drawSpellCheckerAttributes(dirtyRect, in: context)
            // TODO: Add annotation rendering from STAnnotationRenderKey attribute.
            //       Port implementation from AppKit STTextLayoutFragmentView:
            //       - collectAnnotationSegments(in:)
            //       - drawAnnotationBackgrounds(_:in:)
            //       - drawAnnotationUnderlines(_:in:)
            //       - draw*Underline helper methods
        }
    #endif

    #if USE_LAYERS_FOR_GLYPHS
        private func layoutGlyphLayers() {
            // layout each character on separate layer, so it can be animable
            for textLineFragment in layoutFragment.textLineFragments {
                let lineAttributedString = textLineFragment.attributedString.attributedSubstring(from: textLineFragment.characterRange)

                for run in lineAttributedString.line().glyphRuns() {
                    let glyphs = run.glyphs()
                    let glyphPositions = run.glyphPositions()
                    let boundingRects = run.font.boundingRects(of: glyphs)
                    for idx in 0 ..< run.glyphsCount {
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

                        layer.addSublayer(glyphLayer)
                        glyphLayer.setNeedsDisplay()

                        // Exmaple animation
                        // do {
                        //     let animation1 = CABasicAnimation(keyPath: "transform.translation.x")
                        //     animation1.fromValue = Double.random(in: -2...0)
                        //     animation1.toValue = Double.random(in: 0...2)
                        //     animation1.timingFunction = .init(name: .easeInEaseOut)
                        //
                        //     let animation2 = CABasicAnimation(keyPath: "transform.translation.y")
                        //     animation2.fromValue = Double.random(in: -2...0)
                        //     animation2.toValue = Double.random(in: 0...1)
                        //     animation2.timingFunction = .init(name: .linear)
                        //
                        //     let animation3 = CABasicAnimation(keyPath: "transform.rotation.y")
                        //     animation3.fromValue = Double.random(in: -(30 * .pi / 180)...0)
                        //     animation3.toValue = Double.random(in: 0...(30 * .pi / 180))
                        //     animation3.timingFunction = .init(name: .linear)
                        //
                        //     let animation4 = CABasicAnimation(keyPath: "transform.rotation.z")
                        //     animation4.fromValue = Double.random(in: -(15 * .pi / 180)...0)
                        //     animation4.toValue = Double.random(in: 0...(15 * .pi / 180))
                        //     animation4.timingFunction = .init(name: .linear)
                        //
                        //     let groupAnimation = CAAnimationGroup()
                        //     groupAnimation.duration = Double.random(in: 1..<2)
                        //     groupAnimation.animations = [animation1, animation2, animation3, animation4]
                        //     groupAnimation.isRemovedOnCompletion = false
                        //     groupAnimation.autoreverses = true
                        //     groupAnimation.repeatCount = .greatestFiniteMagnitude
                        //     glyphLayer.add(groupAnimation, forKey: "itsmine")
                        // }
                    }
                }
            }
        }
    #endif

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutAttachmentView()
    }

    private func layoutAttachmentView() {
        for attachmentViewProvider in layoutFragment.textAttachmentViewProviders {
            guard let attachmentView = attachmentViewProvider.view else {
                continue
            }

            let layoutFragment = layoutFragment.frameForTextAttachment(at: attachmentViewProvider.location)
            let viewOrig = layoutFragment.origin
            attachmentView.frame.origin = viewOrig
            if attachmentView.superview == nil {
                addSubview(attachmentView)
            }
        }
    }
}

#if USE_LAYERS_FOR_GLYPHS
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

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
#endif
