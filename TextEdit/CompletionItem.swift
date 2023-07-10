import Foundation
import SwiftUI
import STTextView

enum Completion {

    struct Item: STCompletionItem {
        let id: String
        let label: String
        let symbolName: String
        let insertText: String

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: symbolName)
                        .frame(width: 24)

                    Text(label)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

}
