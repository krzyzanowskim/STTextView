//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import SwiftUI

/// Covenience annotation view implementation provided by the framework.
open class STAnnotationLabelView: NSView {

    private struct ContentView<Label: View>: View {
        @Environment(\.isEnabled) private var isEnabled
        var label: Label

        init(_ label: Label) {
            self.label = label
        }

        var body: some View {
            label
                .labelStyle(AnnotationLabelStyle())
                .disabled(!isEnabled)
        }
    }

    private struct AnnotationLabelStyle: LabelStyle {
        @Environment(\.colorScheme) private var colorScheme

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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    public let annotation: STLineAnnotation

    public init<Label: View>(annotation: STLineAnnotation, label: Label) {
        self.annotation = annotation

        super.init(frame: .zero)
        
        let hostingView = NSHostingView(rootView: ContentView(label))
        hostingView.autoresizingMask = [.height, .width]
        addSubview(hostingView)
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .arrow)
    }
}
