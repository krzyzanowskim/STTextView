//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import STTextView

public struct TextView: SwiftUI.View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding private var text: String
    @Binding private var font: NSFont

    public init(
        text: Binding<String>,
        font: Binding<NSFont> = .constant(.preferredFont(forTextStyle: .body))
    ) {
        _text = text
        _font = font
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            font: $font
        )
        .background(.background)
    }
}

private struct TextViewRepresentable: NSViewRepresentable {
    @Environment(\.lineSpacing) private var lineSpacing
    @Environment(\.isEnabled) private var isEnabled

    @Binding var text: String
    @Binding var font: NSFont

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        textView.font = font
        textView.string = text
        textView.delegate = context.coordinator
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        let textView = scrollView.documentView as! STTextView
        textView.isEditable = isEnabled
        textView.isSelectable = isEnabled
    }

    func makeCoordinator() -> TextCoordinator {
        TextCoordinator(parent: self)
    }

    class TextCoordinator: STTextViewDelegate {
        var parent: TextViewRepresentable
        var isUpdating: Bool = false

        init(parent: TextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? STTextView else {
                return
            }

            parent.text = textView.string
        }

    }
}
