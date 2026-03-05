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
    @State private var showCustomGutter = false

    /// Tracks which lines have bookmarks toggled on (by 1-based line number).
    @State private var bookmarkedLines: Set<Int> = []

    /// Tracks which lines have breakpoints active (by 1-based line number).
    @State private var breakpointLines: Set<Int> = []

    private var options: TextView.Options {
        var opts: TextView.Options = [.highlightSelectedLine]
        if wrapLines { opts.insert(.wrapLines) }
        if showLineNumbers && !showCustomGutter { opts.insert(.showLineNumbers) }
        return opts
    }

    var body: some View {
        NavigationStack {
            Group {
                if showCustomGutter {
                    customGutterEditor
                } else {
                    plainEditor
                }
            }
            .ignoresSafeArea(.container)
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
                        Label("Line Numbers", systemImage: showLineNumbers ? "list.number" : "list.bullet").labelStyle(.titleAndIcon)
                    }
                    Toggle(isOn: $showCustomGutter) {
                        Label("Custom Gutter", systemImage: "list.star").labelStyle(.titleAndIcon)
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

    // MARK: - Plain Editor (no gutter or built-in line numbers)

    private var plainEditor: some View {
        TextView(
            text: $text,
            selection: $selection,
            options: options
        )
        .textViewFont(font)
    }

    // MARK: - Custom Gutter Editor

    /// Editor with a custom per-line gutter showing word count, bookmark, and breakpoint.
    private var customGutterEditor: some View {
        TextViewWithGutter(
            text: $text,
            selection: $selection,
            options: options,
            gutterWidth: 64,
            gutterContent: { lineNumber, lineContent in
                CustomGutterLineView(
                    lineNumber: lineNumber,
                    lineContent: lineContent,
                    isBookmarked: bookmarkedLines.contains(lineNumber),
                    hasBreakpoint: breakpointLines.contains(lineNumber),
                    onToggleBookmark: {
                        toggleBookmark(lineNumber)
                    },
                    onToggleBreakpoint: {
                        toggleBreakpoint(lineNumber)
                    }
                )
            }
        )
        .gutterBackground(NSColor(srgbRed: 0.992, green: 0.984, blue: 0.969, alpha: 1))
        .gutterSeparator(color: NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 0.5), width: 1)
        .textViewFont(font)
    }

    // MARK: - Actions

    private func toggleBookmark(_ lineNumber: Int) {
        if bookmarkedLines.contains(lineNumber) {
            bookmarkedLines.remove(lineNumber)
        } else {
            bookmarkedLines.insert(lineNumber)
        }
    }

    private func toggleBreakpoint(_ lineNumber: Int) {
        if breakpointLines.contains(lineNumber) {
            breakpointLines.remove(lineNumber)
        } else {
            breakpointLines.insert(lineNumber)
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

// MARK: - Custom Gutter Line View

/// Per-line gutter view demonstrating word count, toggleable bookmark, and
/// an overhanging breakpoint indicator activated by tapping the number.
///
/// The breakpoint badge intentionally extends past the gutter's trailing edge
/// to demonstrate that custom gutter content can overhang when needed.
private struct CustomGutterLineView: View {
    let lineNumber: Int
    let lineContent: String
    let isBookmarked: Bool
    let hasBreakpoint: Bool
    let onToggleBookmark: () -> Void
    let onToggleBreakpoint: () -> Void

    /// Number of whitespace-separated words on this line.
    private var wordCount: Int {
        let trimmed = lineContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.split(whereSeparator: { $0.isWhitespace }).count
    }

    var body: some View {
        HStack(spacing: 3) {
            Spacer(minLength: 0)

            // Bookmark icon — toggles between outline and filled on click
            Button(action: onToggleBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 9))
                    .foregroundStyle(isBookmarked ? SwiftUI.Color.orange : SwiftUI.Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Word count number — tapping toggles breakpoint
            if hasBreakpoint {
                breakpointBadge
            } else {
                wordCountLabel
            }
        }
        .padding(.trailing, 4)
        .padding(.leading, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    /// Plain word count number — tappable to activate breakpoint.
    private var wordCountLabel: some View {
        Group {
            if wordCount > 0 {
                Text("\(wordCount)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .onTapGesture(perform: onToggleBreakpoint)
            }
        }
    }

    /// Overhanging breakpoint badge — blue rounded rect with white number,
    /// extends ~8pt past the gutter edge to demonstrate overhang capability.
    /// Drop shadow adds depth. Tappable to deactivate.
    private var breakpointBadge: some View {
        Text("\(wordCount > 0 ? wordCount : lineNumber)")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(SwiftUI.Color.accentColor)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 1, y: 1)
            )
            .offset(x: 8) // Overhang past gutter edge
            .onTapGesture(perform: onToggleBreakpoint)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
