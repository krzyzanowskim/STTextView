<p align="center">
  <img width="64" src="https://user-images.githubusercontent.com/758033/235909140-3589bb7d-51a0-4df3-8d71-2dc30fcabc8c.png">
</p>

# STTextView

Performant [macOS](https://www.apple.com/macos) TextView with line numbers and much more. (NSTextView replacement)

The goal of this project is to build [NSTextView](https://developer.apple.com/documentation/appkit/nstextview) replacement component utilizing [TextKit 2](https://developer.apple.com/videos/play/wwdc2021/10061/) framework. [due to many good reasons](#-textkit-2-bug-reports-list).

The component is developed to serve [Swift Studio](https://swiftstudio.app) needs as a **source code editor**.

<img width="100%" alt="Screenshot 2023-04-24 at 02 03 51" src="https://user-images.githubusercontent.com/758033/233873957-3f94a73a-a401-4f54-9631-3002600ba6f8.png">

https://user-images.githubusercontent.com/758033/217397725-1e217c25-24ac-4d9b-9812-b3c7e324a1ca.mp4

[TextKit 2](https://developer.apple.com/forums/tags/wwdc21-10061) was announced during [WWDC 2021](https://developer.apple.com/videos/play/wwdc2021/10061/) as a TextKit 1 replacement for text layout and whatnot. Apple announced that `NSTextView`, the view component specialized for text editing, will adopt TextKit 2 and provide support along TextKit 1 bit. As I started to learn more about `NSTextView` + TextKit2, I realized as of today (Feb 2022), neither `NSTextView` is fully functional, nor TextKit 2 classes are fully functional. Along the way, I reported several bug reports to Apple requesting DTS (support tickets). Eventually, I got blocked by specific bugs that pushed me to start this project.

## ✨ Features

- macOS text system integration
- Performant Text editing
- Line numbers in a ruler view
- Ruler Markers support
- Customization of colors and fonts
- Toggle line wrapping on and off
- Adjust the height of lines
- Highlight/Select ranges in the text view
- Multi-cursor editing
- Search/Replace the text
- Spelling and Grammar
- Dictation
- Display Invisible Characters
- Customizable Completion support
- Smooth scrolling of long content
- LTR (Left To Right) / RTL (Right To Left) layout
- Undo/Redo
- Plugins
- Anchored annotations (via plugin)
- Source Code syntax highlighting (via plugin)

## 🤝 Support & Sponsors

The financial sustainability of the project is possible thanks to the ongoing contributions from our [GitHub Sponsors](https://github.com/sponsors/krzyzanowskim)

### Premium Sponsors

  [Judo](https://judo.app) is a design and build tool for SwiftUI apps that writes production-ready code for you while you’re designing. Eliminate back-and-forth with developers and free them from unrewarding grunt work.

[<img alt="judo.app" width="200" src="https://github-production-user-asset-6210df.s3.amazonaws.com/758033/257891209-932464f9-d756-4ddb-9946-198901ace96f.png" />](https://judo.app)

## 🗓️ Roadmap

STTextView is already well-suited as a text editor component. However, it still needs improvements before the release of v1.0

**Suggest** or **vote** for new features: [Feature Requests](https://github.com/krzyzanowskim/STTextView/discussions/14)

#### Known issues

- undo/redo while typing needs fixes
- text dragging (partially implemented)

## 🚀 Getting Started

`STTextView` is distributed using the [Swift Package Manager](https://www.swift.org/package-manager/). Install it in a project by adding it as a dependency in your `Package.swift` manifest or through “Package Dependencies” in Xcode project settings

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", from: "0.8.0")
    ]
)
```

## Demo Application

The demo applications [TextEdit](TextEdit) and [TextEdit.SwiftUI](TextEdit.SwiftUI) lets you explore the library.
## Plugins

Plugins in an STTextView component offer additional functionalities and customizations beyond the basic text display. They enhance the core capabilities of the text view by adding features such as syntax highlighting, word count tracking, and more. These plugins expand the STTextView's utility while maintaining a modular and adaptable software structure.

- [Plugin-Neon](https://github.com/krzyzanowskim/STTextView-Plugin-Neon) Source Code Syntax Highlighting with [TreeSitter](https://tree-sitter.github.io/tree-sitter/) and [Neon](https://github.com/ChimeHQ/Neon).
- [Plugin-TextFormation](https://github.com/ChimeHQ/STTextView-Plugin-TextFormation) Typing completions with [TextFormation](https://github.com/ChimeHQ/TextFormation).
- [Plugin-Annotations](https://github.com/krzyzanowskim/STTextView-Plugin-Annotations) Anchored annotations (eg. inlined error message)) plugin.
- [Plugin-Template](https://github.com/krzyzanowskim/STTextView-Plugin-Template) Dummy plugin template repository ready bo build new plugin.
- ... add more plugins

## Usage

### SwiftUI

The `TextView` is a [SwiftUI](https://developer.apple.com/xcode/swiftui/) view that wraps the STTextView.

* Support for rich text (attributed string)
* Faster than SwiftUI.TextEdit (https://twitter.com/krzyzanowskim/status/1677628085217243137)

```swift
import STTextViewUI

struct ContentView: View {

    @State private var text = AttributedString("Hello World!")
    @State private var selection: NSRange?

    var body: some View {
        STTextViewUI.TextView(
            text: $text,
            selection: $selection,
            options: [.wrapLines, .highlightSelectedLine],
            plugins: [plugin1(), plugin2()]
        )
        .textViewFont(.preferredFont(forTextStyle: .body))
    }
}
```

### Create a TextView

The `STTextView` is an `NSView` subclass and can be initialized like any other view. It has an API that is similar to the one of NSTextView.

```swift
import STTextView

let textView = STTextView()
view.addSubView(textView)
```

```swift
let textView = STTextView()
let scrollView = NSScrollView()
scrollView.documentView = textView
```

```swift
let scrollView = STTextView.scrollableTextView()
let textView = scrollView.documentView as! STTextView
```

### Customize

The text view can be customized in a variety of ways.

```swift
let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
// Set the line-height to 110%
paragraph.lineHeightMultiple = 1.1
paragraph.defaultTabInterval = 28

// Default Paragraph style
textView.typingAttributes[.paragraphStyle] = paragraph

// Set default font
textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

// Set default text color
textView.textColor = .textColor

// Set text value
textView.string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ornare lobortis sem a vulputate."
textView.addAttributes([.foregroundColor: NSColor.red], range: NSRange(location: 10, length: 5))

// Wrap/No wrap lines to editor width
textView.isHorizontallyResizable = true

// Highlight the selected line.
textView.highlightSelectedLine = true
```

Add line numbers using specialized `STLineNumberRulerView` (specialized subclass of `NSRulerView`)

```swift
let textView = STTextView()
let scrollView = NSScrollView()
scrollView.documentView = textView

// Line numbers
let rulerView = STLineNumberRulerView(textView: textView)
// Configure the ruler view
rulerView.highlightSelectedLine = true
// Allows to set markers.
// rulerView.allowsMarkers = true

// Add to NSScrollView containing STTextView
scrollView.verticalRulerView = rulerView
scrollView.rulersVisible = true
```

Enable an optional search-and-replace find interface inside a view, usually a scroll view.

```swift
textView.isIncrementalSearchingEnabled = true
textView.textFinder.incrementalSearchingShouldDimContentView = true
```

## 🐛 TextKit 2 Bug Reports List

List of **TextKit 2** issues and bugs related to NSTextView and the TextKit framework I reported to Apple so far:

- FB9856587: TextKit2 unexpected additional line fragment for the last line
- FB9925766: NSTextSelectionNavigation.deletionRanges only works at the end of the word
- FB9925647: NSTextLayoutManager.replaceContents(in range: with attributedString:) is documented but is not part of the public API
- FB9907261: NSTextElementProvider.replaceContents(in:with:) does not replace content as documented
- FB9692714: Rendering attributes do not draw properly
- FB9886911: NSTextView can't properly layout and display long lines (this one is nasty since it causes the view to "jump" whenever text attribute updates)
- FB9713415: NSTextView drawInsertionPoint(in:color:turnedOn) is never called
- FB9971054: NSLayoutManager.enumerateCaretOffsetsInLineFragment ignores starting location
- FB9971054: NSTextView assert on selection when setup with TextKit2
- FB9743449, FB10019859: NSTextContentStorage.textElements(for:) returns no element, while enumerateTextElements does return elements
- FB11898356: textSelections(interactingAt:inContainerAt:anchors:modifiers:selecting:bounds:) produces wrong selections for certain locations
- FB12726775: Documentation to the NSTextParagraph.paragraphContentRange is incorrect
- FB13272586: NSTextContainer.size default value is not as documented
- [FB13290979](https://gist.github.com/krzyzanowskim/7adc5ee66be68df2f76b9752476aadfb): NSTextContainer.lineFragmentPadding does not affect end of the fragment usageBoundsForTextContainer rectangle
- [FB13291926](https://gist.github.com/krzyzanowskim/33a2478fa2281b77816acb7a7f6f77ac): NSTextLayoutManager.usageBoundsForTextContainer observer is never trigerred

... I'm aware that the list of issues is not complete. I managed to workaround most of the problems in STTextView.

## Why ST?

(**ST** prefix stands for "**S**wift s**T**udio" because **[SS](https://en.wikipedia.org/wiki/Schutzstaffel)** is not good prefix since 1939)

## Suggestions or Feedback

Start a new [discussion topic](https://github.com/krzyzanowskim/STTextView/discussions) or a pull request.

I'd love to hear from you! Get in touch via X/Twitter [@krzyzanowskim](https://x.com/krzyzanowskim), mastodon [@krzyzanowskim@mastodon.social](https://mastodon.social/@krzyzanowskim).

## License

### Open Source license

If you are creating an open-source application under a license compatible with the [GNU GPL license v3](https://www.gnu.org/licenses/gpl-3.0.html), you may use STTextView under the terms of the GPLv3.

### Commercial license

Get one [starting from €5](https://krzyzanowskim.gumroad.com/l/sttextview).

If you want to use STTextView to develop non-open-sourced products and applications, the Commercial license is appropriate. With this option, your source code is kept proprietary. You won't have to change your whole application source code to an open-source license. [Purchase a STTextView Commercial License](https://krzyzanowskim.gumroad.com/l/sttextview)
