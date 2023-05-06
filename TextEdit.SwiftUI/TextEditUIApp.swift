//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import SwiftUI

@main
struct TextEditUIApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextEditUIDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
