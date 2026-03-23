//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

// MARK: TextAttachment provider

final class MyTextAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        let image = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil)!
        let imageView = NSImageView(image: image)
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(paletteColors: [NSColor.labelColor])
        self.view = imageView
    }

    override func attachmentBounds(
        for _: [NSAttributedString.Key: Any],
        location _: any NSTextLocation,
        textContainer _: NSTextContainer?,
        proposedLineFragment _: CGRect,
        position _: CGPoint
    ) -> CGRect {
        self.view?.bounds ?? .zero
    }
}

final class MyTextAttachment: NSTextAttachment {
    override func viewProvider(
        for parentView: NSView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        let viewProvider = MyTextAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
        viewProvider.tracksTextAttachmentViewBounds = true
        return viewProvider
    }
}

// MARK: Interactive Button Attachment

final class InteractiveButtonAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        let button = NSButton(title: "Click Me!", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        self.view = button
    }

    override func attachmentBounds(
        for _: [NSAttributedString.Key: Any],
        location _: any NSTextLocation,
        textContainer _: NSTextContainer?,
        proposedLineFragment _: CGRect,
        position _: CGPoint
    ) -> CGRect {
        self.view?.bounds ?? CGRect(x: 0, y: 0, width: 80, height: 24)
    }
}

final class InteractiveButtonAttachment: NSTextAttachment {
    override func viewProvider(
        for parentView: NSView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        let viewProvider = InteractiveButtonAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
        viewProvider.tracksTextAttachmentViewBounds = true
        return viewProvider
    }
}
