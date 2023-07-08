//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import STTextView

public struct TextView: SwiftUI.View {

    @frozen
    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let wrapLines = Options(rawValue: 1 << 0)
        public static let highlightSelectedLine = Options(rawValue: 1 << 1)
    }

    @Environment(\.colorScheme) private var colorScheme

    @Binding private var text: AttributedString
    private var font: NSFont
    private let options: Options

    public init(
        text: Binding<AttributedString>,
        font: NSFont = .preferredFont(forTextStyle: .body),
        options: Options = []
    ) {
        _text = text
        self.font = font
        self.options = options
    }

    public init(
        text: Binding<String>,
        font: NSFont = .preferredFont(forTextStyle: .body),
        options: Options = []
    ) {
        self = TextView(
            text: Binding(
                get: {
                    var container = AttributeContainer()
                    // Swift 5.9 bogus warning: Conformance of 'NSFont' to 'Sendable' is unavailable
                    // AttributeScopes.AppKitAttributes.FontAttribute requires NSFont and Sendable
                    // that is impossible compbination.
                    container[AttributeScopes.AppKitAttributes.FontAttribute.self] = font
                    return AttributedString(text.wrappedValue, attributes: container)
                },
                set: { attributedString in
                    text.wrappedValue = String(attributedString.characters[...])
                }
            ),
            font: font,
            options: options
        )
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            font: font,
            options: options
        )
        .background(.background)
    }
}

private struct TextViewRepresentable: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled

    @Binding var text: AttributedString
    let font: NSFont
    let options: TextView.Options

    init(text: Binding<AttributedString>, font: NSFont, options: TextView.Options) {
        self._text = text
        self.font = font
        self.options = options
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        textView.delegate = context.coordinator
        textView.highlightSelectedLine = options.contains(.highlightSelectedLine)
        textView.widthTracksTextView = options.contains(.wrapLines)
        textView.setSelectedRange(NSRange())
        textView.setAttributedString(NSAttributedString(text))
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        let textView = scrollView.documentView as! STTextView

        do {
            context.coordinator.isUpdating = true
            if context.coordinator.isDidChangeText  == false {
                textView.setAttributedString(NSAttributedString(text))
            }
            context.coordinator.isUpdating = false
            context.coordinator.isDidChangeText  = false
        }

        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
        }

        if textView.isSelectable != isEnabled {
            textView.isSelectable = isEnabled
        }

        let wrapLines = options.contains(.wrapLines)
        if wrapLines != textView.widthTracksTextView {
            textView.widthTracksTextView = options.contains(.wrapLines)
        }

        if textView.font != font {
            textView.font = font
        }
    }

    func makeCoordinator() -> TextCoordinator {
        TextCoordinator(parent: self)
    }

    class TextCoordinator: STTextViewDelegate {
        var parent: TextViewRepresentable
        var isUpdating: Bool = false
        var isDidChangeText: Bool = false
        var enqueuedValue: AttributedString?

        init(parent: TextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? STTextView else {
                return
            }

            if !isUpdating {
                let newTextValue = AttributedString(textView.attributedString())
                DispatchQueue.main.async {
                    self.isDidChangeText = true
                    self.parent.text = newTextValue
                }
            }
        }

    }
}
