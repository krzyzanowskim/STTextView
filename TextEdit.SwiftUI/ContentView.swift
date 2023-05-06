//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import SwiftUI
import TextView

struct ContentView: View {
    @Binding var document: TextEditUIDocument

    var body: some View {
        TextView(
            text: $document.text,
            font: .preferredFont(forTextStyle: .body)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(TextEditUIDocument()))
    }
}
