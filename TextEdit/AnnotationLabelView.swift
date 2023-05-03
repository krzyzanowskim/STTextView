import SwiftUI
import Foundation
import STTextView

struct AnnotationLabelView: View {
    let message: String
    let action: (STLineAnnotation) -> Void
    let lineAnnotation: STLineAnnotation

    var body: some View {
        Label {
            Text(message)
                .foregroundColor(.primary)
        } icon: {
            Button {
                action(lineAnnotation)
            } label: {
                ZStack {
                    // the way it draws bothers me
                    // https://twitter.com/krzyzanowskim/status/1527723492002643969
                    Image(systemName: "octagon")
                        .symbolVariant(.fill)
                        .foregroundStyle(.red)

                    Image(systemName: "xmark.octagon")
                        .foregroundStyle(.white)
                }
                .shadow(radius: 1)
            }
            .buttonStyle(.plain)
        }
        .background(Color.yellow)
        .clipShape(RoundedRectangle(cornerRadius:4))
    }
}
