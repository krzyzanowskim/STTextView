//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextViewCommon

/// Protocol for attachment views to communicate with their containing text view
@objc
public protocol STTextAttachmentViewInteracting {
    /// Called when the attachment view is clicked or interacted with
    /// - Parameters:
    ///   - attachment: The text attachment associated with this view
    ///   - location: The location of the attachment in the text
    func attachmentViewDidReceiveInteraction(attachment: NSTextAttachment, at location: NSTextLocation)
}

/// Helper class to bridge attachment view interactions to text view delegates
public class STTextAttachmentViewInteractionBridge: NSObject {
    weak var textView: STTextView?
    weak var attachment: NSTextAttachment?
    var location: NSTextLocation?

    init(textView: STTextView, attachment: NSTextAttachment, location: NSTextLocation) {
        self.textView = textView
        self.attachment = attachment
        self.location = location
        super.init()
    }

    @objc public func handleInteraction(_ sender: Any?) {
        guard let textView,
              let attachment,
              let location else {
            return
        }

        // First, select the attachment in the text view
        textView.selectAttachment(at: location)

        // Then call the delegate method for attachment interaction
        if textView.delegateProxy.textView(textView, shouldAllowInteractionWith: attachment, at: location) {
            _ = textView.delegateProxy.textView(textView, clickedOnAttachment: attachment, at: location)
        }
    }
}

extension STTextView: STTextAttachmentViewInteracting {
    public func attachmentViewDidReceiveInteraction(attachment: NSTextAttachment, at location: NSTextLocation) {
        // First, select the attachment in the text view
        selectAttachment(at: location)

        // Then call the delegate method for attachment interaction
        if delegateProxy.textView(self, shouldAllowInteractionWith: attachment, at: location) {
            _ = delegateProxy.textView(self, clickedOnAttachment: attachment, at: location)
        }
    }
}

/// Extension to help configure attachment views for interaction
public extension NSView {

    /// Configures this view to send attachment interactions to the text view
    /// - Parameters:
    ///   - textView: The text view containing this attachment
    ///   - attachment: The attachment associated with this view
    ///   - location: The location of the attachment in the text
    func setupAttachmentInteraction(textView: STTextView, attachment: NSTextAttachment, location: NSTextLocation) {
        let bridge = STTextAttachmentViewInteractionBridge(textView: textView, attachment: attachment, location: location)

        // Store the bridge as associated object to keep it alive
        objc_setAssociatedObject(self, AssociatedKeys.interactionBridge, bridge, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Configure based on view type
        if let button = self as? NSButton {
            button.target = bridge
            button.action = #selector(STTextAttachmentViewInteractionBridge.handleInteraction(_:))
        } else if let control = self as? NSControl {
            control.target = bridge
            control.action = #selector(STTextAttachmentViewInteractionBridge.handleInteraction(_:))
        } else {
            // For non-control views, add a gesture recognizer
            let tapGesture = NSClickGestureRecognizer(target: bridge, action: #selector(STTextAttachmentViewInteractionBridge.handleInteraction(_:)))
            self.addGestureRecognizer(tapGesture)

            // Store gesture recognizer to prevent it from being deallocated
            objc_setAssociatedObject(self, AssociatedKeys.tapGesture, tapGesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Returns the interaction bridge associated with this view, if any
    var attachmentInteractionBridge: STTextAttachmentViewInteractionBridge? {
        return objc_getAssociatedObject(self, AssociatedKeys.interactionBridge) as? STTextAttachmentViewInteractionBridge
    }
}

private enum AssociatedKeys {
    static var interactionBridge = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    static var tapGesture = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
}
