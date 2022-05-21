# STTextView

The goal of this project is to build [NSTextView](https://developer.apple.com/documentation/appkit/nstextview) replacement component utilizing TextKit2. Because reasons.

The component is developed to serve [Swift Studio](https://swiftstudio.app) needs. (**ST** prefix stands for "**S**wift s**T**udio" because **SS** is not good prefix since 1939)

![Screen Shot 2022-05-21 at 11 44 25](https://user-images.githubusercontent.com/758033/169645959-3beabd29-502d-4db1-ad96-cbfd2238c41a.gif)


[TextKit2](https://developer.apple.com/forums/tags/wwdc21-10061) was announced during [WWDC 2021](https://developer.apple.com/videos/play/wwdc2021/10061/) as a TextKit replacement for text layout and whatnot. Apple announced that `NSTextView`, the view component specialized for text editing, will adopt TextKit2 and provide support along TextKit1 bits. As I started to learn more about `NSTextView` + TextKit2, I realized as of today (Feb 2022), neither NSTextView is fully functional, nor TextKit2 classes are fully functional. Along the way, I reported several bug reports to Apple requested DTS (support tickets). Eventually, I've got blocked by specific bugs that pushed me to start this project.

## Bug Reports List

List of issues I reported to Apple so far:

- FB9856587: TextKit2 unexpected additional line fragment for last line
- FB9925766: NSTextSelectionNavigation.deletionRanges only works at the end of the word
- FB9925647: NSTextLayoutManager.replaceContents(in range: with attributedString:) is documented but is not part of the public API
- FB9907261: NSTextElementProvider.replaceContents(in:with:) does not replace content as documented
- FB9692714: Rendering attributes does not draw properly
- FB9886911: NSTextView can't properly layout and display long lines (this one is nasty since it causes the view "jump" whenever text attribute updates)
- FB9713415: NSTextView drawInsertionPoint(in:color:turnedOn) is never called
- FB9971054: NSLayoutManager.enumerateCaretOffsetsInLineFragment ignores starting location
- FB9971054: NSTextView assert on selection when setup with TextKit2
- FB9743449, FB10019859: NSTextContentStorage.textElements(for:) returns no element, while enumerateTextElements does return elements

... I'm aware that the list of issues is not complete.

## Integration

Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/krzyzanowskim/STTextView")
]
```

## Use

```swift
let textView = STTextView()

let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
paragraph.lineHeightMultiple = 1.1
paragraph.defaultTabInterval = 28

textView.defaultParagraphStyle = paragraph
textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
textView.textColor = .textColor
textView.string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ornare lobortis sem a vulputate."
textView.addAttributes([.foregroundColor: NSColor.red], range: NSRange(location: 10, length: 5))
textView.widthTracksTextView = true
textView.highlightSelectedLine = true
textView.lineNumbersVisible = true
textView.delegate = self

let scrollView = NSScrollView()
scrollView.documentView = textView

// Line numbers
scrollView.verticalRulerView = STLineNumberRulerView(textView: textView, scrollView: scrollView)
scrollView.rulersVisible = true

```

## Suggestions or Feedback

I'd love to hear from you! Get in touch via twitter [@krzyzanowskim](https://twitter.com/krzyzanowskim), or a pull request.

## License

### Commercial license
If you want to use STTextView to develop non open sourced product, and applications, the Commercial license is the appropriate license. With this option, your source code is kept proprietary. Which means, you won't have to change your whole application source code to an open source license. [Purchase a STTextView Commercial License](https://krzyzanowskim.gumroad.com/l/sttextview)

### Open source license
If you are creating an open source application under a license compatible with the [GNU GPL license v3](https://www.gnu.org/licenses/gpl-3.0.html), you may use STTextView under the terms of the GPLv3.


