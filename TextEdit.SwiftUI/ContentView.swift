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
    @State private var showLineNumbers = true
    @State private var showCustomGutter = false

    /// Tracks which lines have bookmarks toggled on (by 1-based line number).
    @State private var bookmarkedLines: Set<Int> = [3]

    /// Tracks which lines have breakpoints active (by 1-based line number).
    @State private var breakpointLines: Set<Int> = [4]

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
                    bookmarkedLines: $bookmarkedLines,
                    breakpointLines: $breakpointLines
                )
            }
        )
        .gutterBackground(NSColor(srgbRed: 0.992, green: 0.984, blue: 0.969, alpha: 1))
        .gutterSeparator(color: NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 0.5), width: 2)
        .textViewFont(font)
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
/// Uses `@Binding` to parent state sets instead of action closures — this
/// avoids `@MainActor` closure type conflicts with Xcode preview thunking.
///
/// When a breakpoint is active, the entire gutter row shows the Union-shaped
/// badge (matching the Figma design) that overhangs past the gutter edge.
/// When inactive, the row shows a bookmark icon and the word count number.
private struct CustomGutterLineView: View {
    let lineNumber: Int
    let lineContent: String
    @Binding var bookmarkedLines: Set<Int>
    @Binding var breakpointLines: Set<Int>

    private var isBookmarked: Bool { bookmarkedLines.contains(lineNumber) }
    private var hasBreakpoint: Bool { breakpointLines.contains(lineNumber) }

    /// Number of whitespace-separated words on this line.
    private var wordCount: Int {
        let trimmed = lineContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.split(whereSeparator: { $0.isWhitespace }).count
    }

    var body: some View {
        HStack(spacing: 6) {
            Spacer(minLength: 0)

            // Bookmark icon — always visible, independent of breakpoint state
            Button {
                if isBookmarked {
                    bookmarkedLines.remove(lineNumber)
                } else {
                    bookmarkedLines.insert(lineNumber)
                }
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 11))
                    .foregroundStyle(isBookmarked ? SwiftUI.Color.orange : SwiftUI.Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Word count or breakpoint badge — breakpoint overlays the
            // same fixed-width slot so the number doesn't jump.
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
    /// Uses fixed-width frame so the bookmark icon stays in place
    /// regardless of whether a count is shown.
    private var wordCountLabel: some View {
        Text(wordCount > 0 ? "\(wordCount)" : "")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(minWidth: 18, alignment: .trailing)
            .onTapGesture {
                if wordCount > 0 {
                    breakpointLines.insert(lineNumber)
                }
            }
    }

    /// Breakpoint badge using the Union shape from the Figma design.
    /// Text uses same font/frame as wordCountLabel so the number doesn't jump.
    /// Shape tip reaches the separator (offset compensates trailing padding)
    /// but stays within gutter bounds.
    private var breakpointBadge: some View {
        Text(wordCount > 0 ? "\(wordCount)" : "")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .frame(minWidth: 18, alignment: .trailing)
            .background(alignment: .trailing) {
                BreakpointShape()
                    .fill(SwiftUI.Color.accentColor)
                    .frame(width: 28, height: 15)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 1, y: 1)
                    .offset(x: 4) // tip reaches separator (compensates trailing padding)
            }
            .onTapGesture {
                breakpointLines.remove(lineNumber)
            }
    }
}

// MARK: - Breakpoint Shape (from Figma)

/// Arrow-right tab shape for breakpoint indicators, exported from Figma.
/// Rounded left edges with a pointed right side, similar to Xcode's breakpoint indicator.
/// Designed at 28×15pt.
private struct BreakpointShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.7966607881 * width, y: 0))
        path.addCurve(to: CGPoint(x: 0.9005266779 * width, y: 0.0959198282 * height), control1: CGPoint(x: 0.8428305143 * width, y: 0.0000007783 * height), control2: CGPoint(x: 0.8780923153 * width, y: 0.0342482898 * height))
        path.addCurve(to: CGPoint(x: 0.9999994484 * width, y: 0.5007874016 * height), control1: CGPoint(x: 0.9425928167 * width, y: 0.2115586518 * height), control2: CGPoint(x: 1.0002802524 * width, y: 0.3531960926 * height))
        path.addCurve(to: CGPoint(x: 0.9038528967 * width, y: 0.8949176807 * height), control1: CGPoint(x: 0.9997174622 * width, y: 0.6488275483 * height), control2: CGPoint(x: 0.9433396447 * width, y: 0.7907980917 * height))
        path.addCurve(to: CGPoint(x: 0.7966607881 * width, y: height), control1: CGPoint(x: 0.8795991788 * width, y: 0.9588704573 * height), control2: CGPoint(x: 0.8452111369 * width, y: 0.9999991936 * height))
        path.addLine(to: CGPoint(x: 0.129785293 * width, y: height))
        path.addCurve(to: CGPoint(x: 0, y: 0.7102362205 * height), control1: CGPoint(x: 0.0483242729 * width, y: height), control2: CGPoint(x: 0.0000000978 * width, y: 0.8944942706 * height))
        path.addLine(to: CGPoint(x: 0, y: 0.2897637795 * height))
        path.addCurve(to: CGPoint(x: 0.129785293 * width, y: 0), control1: CGPoint(x: 0.0000000247 * width, y: 0.1070872608 * height), control2: CGPoint(x: 0.0483242116 * width, y: 0))
        path.addLine(to: CGPoint(x: 0.7966607881 * width, y: 0))
        path.closeSubpath()
        return path
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
