//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import SwiftUI
import STTextViewUI

struct ContentView: View {
    @State private var text: AttributedString = ""
    @State private var selection: NSRange?
    @State private var counter = 0

    var body: some View {
        VStack(spacing: 0) {
            // this is fast
            STTextViewUI.TextView(
                text: $text,
                selection: $selection,
                options: [.wrapLines, .highlightSelectedLine]
            )
            .textViewFont(.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))

            // Button("Modify") {
            //     text.insert(AttributedString("\(counter)\n"), at: text.startIndex)
            //     counter += 1
            //      selection = NSRange(location: 0, length: 3)
            // }

            // SwiftUI is slow, I wouldn't use it
            //
            // SwiftUI.TextEditor(text: Binding(get: { String(text.characters) }, set: { text = AttributedString($0) }))
            //    .font(.body)

            HStack {
                if let selection {
                    Text("Location: \(selection.location)")
                } else {
                    Text("No selection")
                }

                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
        }
        .onAppear {
            loadContent()
        }
    }

    private func loadContent() {
        let string = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        self.text = AttributedString(string)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
