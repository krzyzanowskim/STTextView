//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import SwiftUI
import STTextViewUI

struct ContentView: View {
    @State private var text = AttributedString(try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!))
    @State private var counter = 0

    var body: some View {
        VStack {

            // this is fast
            STTextViewUI.TextView(
                text: $text,
                font: .preferredFont(forTextStyle: .body),
                options: [.wrapLines, .highlightSelectedLine]
            )

            /*
            Button("Modify") {
                text.insert(AttributedString("\(counter)\n"), at: text.startIndex)
                counter += 1
            }

            // SwiftUI is slow, I wouldn't use it
            SwiftUI.TextEditor(text: Binding(get: { String(text.characters) }, set: { text = AttributedString($0) }))
                .font(.body)
             
            */
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
