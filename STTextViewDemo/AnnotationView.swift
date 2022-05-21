//
//  AnnotationView.swift
//  STTextViewDemo
//
//  Created by Marcin Krzyzanowski on 20/05/2022.
//

import Foundation
import SwiftUI
import STTextView

final class AnnotationView: NSControl {

    struct ContentView: View {
        let message: String
        let onClose: () -> Void

        var body: some View {
            HStack(spacing: 0) {
                Label {
                    Text(message)
                } icon: {
                    Button {
                        onClose()
                    } label: {
                        ZStack {
                            // the way it draws bothers me
                            // https://twitter.com/krzyzanowskim/status/1527723492002643969
                            Image(systemName: "octagon")
                                .symbolVariant(.fill)
                                .foregroundStyle(.red)

                            Image(systemName: "xmark.octagon")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .labelStyle(AnnotationLabelStyle())

                Spacer()
            }
        }
    }

    struct AnnotationLabelStyle: LabelStyle {

        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center, spacing: 0) {
                configuration.icon
                    .padding(.horizontal, 4)
                    .controlSize(.large)
                    .contentShape(Rectangle())

                Rectangle()
                    .foregroundColor(.white)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)

                configuration.title
                    .padding(.leading, 4)
                    .padding(.trailing, 16)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
        }
    }

    let lineAnnotation: STTextView.LineAnnotation

    init(lineAnnotation: STTextView.LineAnnotation, font: NSFont) {
        self.lineAnnotation = lineAnnotation
        super.init(frame: .zero)

        self.font = font

        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.backgroundColor = NSColor.systemRed.lighter(withLevel: 0.5).cgColor

        let hostingView = NSHostingView(rootView:
            ContentView(message: "Annotation message") {
                if let action = self.action, let target = self.target {
                    NSApp.sendAction(action, to: target, from: self)
                }
            }
            .font(Font(self.font!))
        )
        hostingView.autoresizingMask = [.height, .width]
        addSubview(hostingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private extension NSColor {

    func lighter(withLevel value: CGFloat = 0.3) -> NSColor {
        guard let color = usingColorSpace(.deviceRGB) else {
            return self
        }

        return NSColor(
            hue: color.hueComponent,
            saturation: max(color.saturationComponent - value, 0.0),
            brightness: color.brightnessComponent,
            alpha: color.alphaComponent)
    }
}
