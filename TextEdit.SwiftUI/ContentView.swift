//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import SwiftUI
import STTextViewSwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
typealias Font = NSFont
typealias Color = NSColor
let textColor = Color.textColor
#endif
#if canImport(UIKit)
typealias Font = UIFont
typealias Color = UIColor
let textColor = Color.label
#endif

struct ContentView: View {
    @State private var text: AttributedString = ""
    @State private var selection: NSRange?
    @State private var font = Font.monospacedSystemFont(ofSize: 0, weight: .medium)
    @State private var wrapLines = true
    @State private var showLineNumbers = false

    private var options: TextView.Options {
        var opts: TextView.Options = [.highlightSelectedLine]
        if wrapLines { opts.insert(.wrapLines) }
        if showLineNumbers { opts.insert(.showLineNumbers) }
        return opts
    }

    var body: some View {
        NavigationStack {
            // Issue #91: Using .wrapLines and setting text attributes in onAppear
            // previously caused an infinite loop. Now fixed.
            TextView(
                text: $text,
                selection: $selection,
                options: options
            )
            .textViewFont(font)
            .navigationTitle("STTextView")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItemGroup {
                    Toggle(isOn: $wrapLines) {
                        Label("Wrap Lines", systemImage: wrapLines ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
                    }
                    Toggle(isOn: $showLineNumbers) {
                        Label("Line Numbers", systemImage: showLineNumbers ? "list.number" : "list.bullet")
                    }
                }
            }
        }
        .onAppear {
            // This triggers the issue #91 scenario:
            // Setting text with attributes in onAppear with .wrapLines option
            loadContent()
        }
    }

    private func loadContent() {
        let string = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
        self.text = AttributedString(
            string.prefix(4096),
            attributes: AttributeContainer([.foregroundColor: textColor, .font: font])
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
