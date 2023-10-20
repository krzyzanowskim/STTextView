import Foundation
import SwiftUI
import STTextView

enum Completion {

    struct Item: STCompletionItem {
        let id: String
        let label: String
        let symbolName: String
        let insertText: String

        var view: NSView {
            NSHostingView(rootView: VStack(alignment: .leading) {
                HStack {
                    Image(systemName: symbolName)
                        .frame(width: 24)

                    Text(label)

                    Spacer()
                }
            })
        }
    }

}
