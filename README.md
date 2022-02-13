# STTextView

The goal of this project is to build [NSTextView](https://developer.apple.com/documentation/appkit/nstextview) replacement component utilizing TextKit2. Because reasons.

The component is developed to serve [Swift Studio](https://swiftstudio.app) needs. (**ST** prefix stands for "Swift sTudio" because **SS** is not good prefix since 1939)

https://user-images.githubusercontent.com/758033/154321737-5d757d75-fdc3-46da-92b6-0d149276c3ec.mov

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
textView.string = try! String(contentsOf: Bundle.main.url(forResource: "content", withExtension: "txt")!)
textView.addAttributes([.foregroundColor: NSColor.red], range: NSRange(location: 10, length: 5))
textView.widthTracksTextView = true
textView.delegate = self
```

### Suggestions or Feedback

I'd love to hear from you! Get in touch via twitter [@krzyzanowskim](https://twitter.com/krzyzanowskim), an issue, or a pull request.



