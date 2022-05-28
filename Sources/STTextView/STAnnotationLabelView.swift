//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import SwiftUI

/// Covenience annotation view implementation provided by the framework.
public final class STAnnotationLabelView: NSView {

    private struct ContentView<Label: View>: View {
        @Environment(\.isEnabled) private var isEnabled
        @ViewBuilder var label: () -> Label

        var body: some View {
            HStack(spacing: 0) {
                label().labelStyle(AnnotationLabelStyle())
                Spacer()
            }
            .disabled(!isEnabled)
        }
    }

    private struct AnnotationLabelStyle: LabelStyle {

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
                    .truncationMode(.tail)
                    .textSelection(.enabled)
            }
        }
    }

    public let annotation: STLineAnnotation

    public init<Label: View>(annotation: STLineAnnotation, @ViewBuilder label: @escaping () -> Label) {
        self.annotation = annotation

        super.init(frame: .zero)
        
        let hostingView = NSHostingView(rootView: ContentView(label: label))
        hostingView.autoresizingMask = [.height, .width]
        addSubview(hostingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
