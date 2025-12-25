<img height="45" src="https://user-images.githubusercontent.com/758033/235909140-3589bb7d-51a0-4df3-8d71-2dc30fcabc8c.png">

# STTextView

Performant [macOS](https://www.apple.com/macos) and [iOS](https://www.apple.com/ios) TextView with line numbers and much more. (NSTextView/UITextView reimplementation)

The goal of this project is to build [NSTextView](https://developer.apple.com/documentation/appkit/nstextview)/[UITextView](https://developer.apple.com/documentation/uikit/uitextview) replacement reusable component utilizing [TextKit 2](https://developer.apple.com/videos/play/wwdc2021/10061/) framework. [due to many good reasons](#-textkit-2-bug-reports-list).

The component is mainly developed to serve [Swift Studio](https://swiftstudio.app) needs as a **source code editor**.


![Poster](https://github.com/user-attachments/assets/58b1a58b-d8bd-44d0-9946-2336335f3b0d)

[TextKit 2](https://developer.apple.com/forums/tags/wwdc21-10061) was announced during [WWDC 2021](https://developer.apple.com/videos/play/wwdc2021/10061/) as a TextKit 1 replacement for text layout and whatnot. Apple announced that `NSTextView`, the view component specialized for text editing, will adopt TextKit 2 and provide support along TextKit 1 bit. As I started to learn more about `NSTextView` + TextKit2, I realized that as of today (Feb 2022), neither `NSTextView` nor TextKit 2 classes are fully functional. Along the way, I reported several bug reports to Apple requesting DTS (support tickets). Eventually, I got blocked by specific bugs that pushed me to start this project.

## Platform Requirements

- **macOS**: 14.0+
- **iOS**: 16.0+
- **Mac Catalyst**: 16.0+
- **Swift**: 5.9+
- **Xcode**: 26.0+

## Features

- macOS text system integration
- Performant Text editing
- Display line numbers
- Display invisible characters
- Customization of colors and fonts
- Toggle line wrapping on and off
- Adjust the height of lines
- Highlight/Select ranges in the text view
- Multi-cursor editing
- Search/Replace the text
- Spelling and Grammar
- Dictation
- Customizable Completion support
- Smooth scrolling of long content
- LTR (Left To Right) / RTL (Right To Left) layout
- Undo/Redo
- Plugins
- Anchored annotations (via plugin)
- Source Code syntax highlighting (via plugin)

<div align="center">
  <video src="https://github.com/user-attachments/assets/e18c058b-8a58-47e0-a57c-a3b01f3d93db" width="90%" />
</div>

## Roadmap

**Suggest** or **vote** for new features: [Feature Requests](https://github.com/krzyzanowskim/STTextView/discussions/14)

## Getting Started

`STTextView` is distributed using the [Swift Package Manager](https://www.swift.org/package-manager/). Install it in a project by adding it as a dependency in your `Package.swift` manifest or through “Package Dependencies” in Xcode project settings

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", from: "2.2.0")
    ]
)
```

## Demo Application

The demo applications [TextEdit](TextEdit) and [TextEdit.SwiftUI](TextEdit.SwiftUI) lets you explore the library.

## Usage

### Create a TextView

The `STTextView` is an `NSView` subclass and can be initialized like any other view. It has an API that is similar to that of NSTextView.

```swift
import STTextView

let textView = STTextView()
view.addSubview(textView)
```

(macOS) add to scroll view

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
// Set the line-height to 120%
paragraph.lineHeightMultiple = 1.2
paragraph.defaultTabInterval = 28

// Default Paragraph style
textView.typingAttributes[.paragraphStyle] = paragraph

// Set default font
textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

// Set default text color
textView.textColor = .textColor

// Set text value
textView.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ornare lobortis sem a vulputate."
textView.addAttributes([.foregroundColor: NSColor.red], range: NSRange(location: 10, length: 5))

// Wrap/No wrap lines to editor width
textView.isHorizontallyResizable = true

// Highlight the selected line.
textView.highlightSelectedLine = true
```

Add gutter with line numbers

```swift
textView.showsLineNumbers = true
textView.gutterView?.drawSeparator = true
```

(macOS) Enable an optional search-and-replace find interface inside a view, usually a scroll view.

```swift
textView.isIncrementalSearchingEnabled = true
textView.textFinder.incrementalSearchingShouldDimContentView = true
```

### SwiftUI

```swift
import STTextViewSwiftUI

struct ContentView: View {
    @State private var text = AttributedString("Hello World!")

    var body: some View {
        TextView(
            text: $text,
            options: [.wrapLines, .highlightSelectedLine, .showLineNumbers]
        )
        .textViewFont(.monospacedSystemFont(ofSize: 14, weight: .regular))
    }
}
```

## Plugins

Plugins in an STTextView component offer additional functionalities and customizations beyond the simple text display. They enhance the core capabilities of the text view by adding features such as syntax highlighting, word count tracking, and more. These plugins expand the STTextView's utility while maintaining a modular and adaptable software structure.

- [Plugin-Neon](https://github.com/krzyzanowskim/STTextView-Plugin-Neon) Source Code Syntax Highlighting with [TreeSitter](https://tree-sitter.github.io/tree-sitter/) and [Neon](https://github.com/ChimeHQ/Neon).
- [Plugin-TextFormation](https://github.com/krzyzanowskim/STTextView-Plugin-TextFormation) Typing completions with [TextFormation](https://github.com/ChimeHQ/TextFormation).
- [Plugin-Annotations](https://github.com/krzyzanowskim/STTextView-Plugin-Annotations) Anchored annotations (eg. inlined error message)) plugin.
- [Plugin-Template](https://github.com/krzyzanowskim/STTextView-Plugin-Template) Dummy plugin template repository ready to build new plugin.
- ... [add more](https://github.com/topics/sttextview) plugins

### Plugin Development

To create a custom plugin:

1. **Implement the STPlugin protocol**:
```swift
class MyPlugin: STPlugin {
    func setUp(context: STPluginContext) {
        // Initialize your plugin
    }
    
    func tearDown() {
        // Clean up resources
    }
}
```

2. **Use STPluginContext for host communication**:
   - Access the text view and its properties
   - Subscribe to text changes and events
   - Modify text attributes and selections

3. **Handle events via STPluginEvents**:
   - Text changes
   - Selection changes
   - Layout updates
   - View lifecycle events

4. **Add the plugin to your text view**:
```swift
let plugin = MyPlugin()
textView.addPlugin(plugin)
```

For a complete example, see the [Plugin-Template](https://github.com/krzyzanowskim/STTextView-Plugin-Template) repository.

## Architecture Overview

STTextView uses a modular architecture with platform-specific implementations:

```
STTextView (umbrella target)
├── STTextViewCommon (shared code)
├── STTextViewAppKit (macOS implementation)
├── STTextViewUIKit (iOS/Catalyst implementation)
├── STTextViewSwiftUI (SwiftUI wrappers)
└── STObjCLandShim (Objective-C bridging)
```

### Core Components

- **STTextView**: Main view that coordinates all components
- **STTextContainerView**: Renders text fragments and insertion point
- **STSelectionView**: Handles selection overlays
- **STGutterView**: Optional line numbers and markers
- **STLineHighlightView**: Current line highlighting

### TextKit 2 Integration

Text layout is managed through custom TextKit 2 components:
- **STTextLayoutManager**: Custom NSTextLayoutManager subclass
- **STTextContentStorage**: NSTextContentStorage subclass with performance optimizations
- **STTextLayoutFragment**: Custom fragment rendering

## 🐛 TextKit 2 Bug Reports List

List of issues and bugs related to TextKit, NSTextView, AppKit, UIKit and related frameworks framework I reported to Apple so far:

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
- [FB13291926](https://gist.github.com/krzyzanowskim/33a2478fa2281b77816acb7a7f6f77ac): NSTextLayoutManager.usageBoundsForTextContainer observer is never trigerred (Fixed again in macOS 15.6)
- [FB13789916](https://gist.github.com/krzyzanowskim/340c5810fc427e346b7c4b06d46b1e10): NSTextInputClient.setMarkedText provide bogus selection range for Chinese keyboard
- [FB14700414](https://gist.github.com/krzyzanowskim/0a83eb9d5303016b277920a6b7c9f9fc): NSTextList doesn't work since macOS 14 (regression)
- [FB15131180](https://gist.github.com/krzyzanowskim/510ecf8df259d779e22df8ad13c256c0): TextKit extra line frame is incorrect and does not respect layout fragment size (regression)
- [FB17020435](https://gist.github.com/krzyzanowskim/da247e1a9f5f94f0e14a1e3047b86e59): enumerateCaretOffsetsInLineFragmentAtLocation:usingBlock: documentation is not accurate 
- [FB19698121](https://gist.github.com/krzyzanowskim/4d831e0f44035b605768ff9d2a4c285e): TextKit 2 undocumented and unexpected behavior in textViewportLayoutControllerDidLayout
- [FB21059465](https://gist.github.com/krzyzanowskim/d2c5d41b86096ccb19b110cf7a5514c8): NSScrollView horizontal floating subview does not respect insets 

... I'm aware that the list of issues is not complete. I managed to workaround most of the problems in STTextView.

## Why ST?

(**ST** prefix stands for "**S**wift s**T**udio" because **[SS](https://en.wikipedia.org/wiki/Schutzstaffel)** is not good prefix since 1939)

## Suggestions or Feedback

Start a new [discussion topic](https://github.com/krzyzanowskim/STTextView/discussions) or a pull request.

I'd love to hear from you! Get in touch via X/Twitter [@krzyzanowskim](https://x.com/krzyzanowskim), Mastodon [@krzyzanowskim@mastodon.social](https://mastodon.social/@krzyzanowskim).

## License

By using the Software, you accept the terms of the [License](LICENSE.md). The STTextView software is copyrighted by Marcin Krzyżanowski.
If use of the software under the [GPL v3.0](https://www.gnu.org/licenses/gpl-3.0.html) does not satisfy your organization’s legal department, [commercial licenses are available](https://krzyzanowskim.gumroad.com/l/sttextview). Feel free to contact for more details.
