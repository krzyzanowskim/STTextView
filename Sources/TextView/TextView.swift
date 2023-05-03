//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI
import STTextView

public struct TextView: SwiftUI.View {
    @State private var string: String = ""

    public var body: some View {
        TextViewRepresentable(
            string: $string
        )
    }

}

private struct TextViewRepresentable: NSViewRepresentable {
    @Binding var string: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let textView = scrollView.documentView as! STTextView
        textView.string = string
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! STTextView
        textView.string = string
    }
}
