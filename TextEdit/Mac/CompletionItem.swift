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
            NSHostingView(rootView: ItemView(label: label, symbolName: symbolName))
        }
    }

}

private struct ItemView: View {
    @Environment(\.colorScheme)
    var colorScheme

    let label: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: symbolName)
                    .symbolRenderingMode(.multicolor)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.accentColor, Color(nsColor: .secondaryLabelColor))
                    .frame(maxWidth: 12)
                    .cornerRadius(2)

                Text(label)
                    .fontWeight(.regular)
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))

                Spacer()
            }
            .monospacedDigit()
            .padding(.horizontal, 6)
        }
    }
}
