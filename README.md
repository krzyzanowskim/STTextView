# STTextView

The goal of this project is to build [NSTextView](https://developer.apple.com/documentation/appkit/nstextview) replacement component utilizing TextKit2. Because reasons.

The component is developed to serve [Swift Studio](https://swiftstudio.app) needs. (**ST** prefix stands for "**S**wift s**T**udio" because **SS** is not good prefix since 1939)

https://user-images.githubusercontent.com/758033/155702958-cdc9e3a4-275a-4953-b5bb-28907041fd21.mov

[TextKit2](https://developer.apple.com/forums/tags/wwdc21-10061) was announced during [WWDC 2021](https://developer.apple.com/videos/play/wwdc2021/10061/) as an TextKit replacement for text layout and whatnot. Apple announced that `NSTextView`, the view component specialized for text editing will adopt TextKit2 and provide support along TextKit1 bits. As I started to learn more about NSTextView + TextKit2 I realized as of today (Feb 2022) neither NSTextView is fully functional, nor TextKit2 classess are fully functional. Along the way I reported several bug reports to Apple, requested DTS (support tickets). Eventually I've got blocked by certain bugs that pushed me to start this project.


- FB9856587: TextKit2 unexpected additional line fragment for last line
- FB9925766: NSTextSelectionNavigation.deletionRanges only works at the end of the word
- FB9925647: NSTextLayoutManager.replaceContents(in range:  with attributedString:) is documented but is not part of the public API
- FB9907261: NSTextElementProvider.replaceContents(in:with:) does not replace content as documented
- FB9692714: Rendering attributes does not draw properly
- FB9886911: NSTextView can't properly layout and display long lines (this one is especially bad since it cause the view "jump" whenever text attribute updates)
- FB9713415: NSTextView drawInsertionPoint(in:color:turnedOn) is never called

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
textView.textColor = .labelColor
textView.string = "text content"
textView.addAttributes([.foregroundColor: NSColor.red], range: NSRange(location: 10, length: 5))
textView.widthTracksTextView = true
textView.delegate = self
```

### Suggestions or Feedback

I'd love to hear from you! Get in touch via twitter [@krzyzanowskim](https://twitter.com/krzyzanowskim), an issue, or a pull request.



