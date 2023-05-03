//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import STTextView

public struct TextView: SwiftUI.View {
    @Binding private var text: String

    public init(text: Binding<String>) {
        _text = text
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text
        )
    }

}

private struct TextViewRepresentable: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! STTextView
        textView.string = text
    }
}
