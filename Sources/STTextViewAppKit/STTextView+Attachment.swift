//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextViewCommon

public extension STTextView {

    // MARK: - Attachment Management

    /// Returns all text attachments in the specified range.
    /// - Parameter range: The range to search for attachments. If nil, searches the entire document.
    /// - Returns: An array of tuples containing the attachment and its range in the document.
    func textAttachments(in range: NSTextRange? = nil) -> [(attachment: NSTextAttachment, range: NSTextRange)] {
        let searchRange = range ?? textLayoutManager.documentRange
        var attachments: [(attachment: NSTextAttachment, range: NSTextRange)] = []

        guard let attributedString = textContentManager.attributedString(in: searchRange) else {
            return attachments
        }

        attributedString.enumerateAttribute(.attachment, in: attributedString.range, options: []) { value, attributeRange, _ in
            guard let attachment = value as? NSTextAttachment,
                  let startLocation = textLayoutManager.location(searchRange.location, offsetBy: attributeRange.location),
                  let endLocation = textLayoutManager.location(startLocation, offsetBy: attributeRange.length),
                  let textRange = NSTextRange(location: startLocation, end: endLocation) else {
                return
            }

            attachments.append((attachment: attachment, range: textRange))
        }

        return attachments
    }

    /// Returns the text attachment at the specified location, if any.
    /// - Parameter location: The location to check for an attachment.
    /// - Returns: The text attachment at the location, or nil if none exists.
    func textAttachment(at location: NSTextLocation) -> NSTextAttachment? {
        return textLayoutManager.textAttributedString(at: location)?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
    }

    /// Returns the range of the text attachment at the specified location.
    /// - Parameter location: The location within an attachment.
    /// - Returns: The range of the attachment, or nil if no attachment exists at the location.
    func textAttachmentRange(at location: NSTextLocation) -> NSTextRange? {
        guard let attributedString = textLayoutManager.textAttributedString(at: location) else {
            return nil
        }

        var effectiveRange = NSRange(location: 0, length: 0)
        let attachment = attributedString.attribute(.attachment, at: 0, effectiveRange: &effectiveRange)

        guard attachment is NSTextAttachment else {
            return nil
        }

        // Convert back to document coordinates
        guard let startLocation = textLayoutManager.location(location, offsetBy: effectiveRange.location),
              let endLocation = textLayoutManager.location(startLocation, offsetBy: effectiveRange.length) else {
            return nil
        }

        return NSTextRange(location: startLocation, end: endLocation)
    }

    /// Replaces the attachment at the specified range with a new attachment.
    /// - Parameters:
    ///   - range: The range containing the attachment to replace.
    ///   - attachment: The new attachment to insert.
    func replaceAttachment(in range: NSTextRange, with attachment: NSTextAttachment) {
        let attributedString = NSAttributedString(attachment: attachment)
        replaceCharacters(in: range, with: attributedString, allowsTypingCoalescing: false)
    }

    /// Removes the attachment at the specified range.
    /// - Parameter range: The range containing the attachment to remove.
    func removeAttachment(in range: NSTextRange) {
        replaceCharacters(in: range, with: "", useTypingAttributes: true, allowsTypingCoalescing: false)
    }

    /// Inserts a text attachment at the specified location.
    /// - Parameters:
    ///   - attachment: The attachment to insert.
    ///   - location: The location where to insert the attachment.
    func insertAttachment(_ attachment: NSTextAttachment, at location: NSTextLocation) {
        let attributedString = NSAttributedString(attachment: attachment)
        let range = NSTextRange(location: location)
        replaceCharacters(in: range, with: attributedString, allowsTypingCoalescing: false)
    }

    // MARK: - Attachment View Management

    /// Returns all currently visible attachment views.
    /// - Returns: An array of attachment views that are currently visible.
    func visibleAttachmentViews() -> [NSView] {
        var attachmentViews: [NSView] = []

        for fragmentView in contentViewportView.subviews.compactMap({ $0 as? STTextLayoutFragmentView }) {
            for provider in fragmentView.layoutFragment.textAttachmentViewProviders {
                if let view = provider.view {
                    attachmentViews.append(view)
                }
            }
        }

        return attachmentViews
    }

    /// Returns the attachment view at the specified location, if any.
    /// - Parameter location: The location to check for an attachment view.
    /// - Returns: The attachment view at the location, or nil if none exists.
    func attachmentView(at location: NSTextLocation) -> NSView? {
        guard let layoutFragment = textLayoutManager.textLayoutFragment(for: location),
              let _ = fragmentViewMap.object(forKey: layoutFragment) else {
            return nil
        }

        // Find attachment at the location
        if let attachment = textAttachment(at: location) {
            for provider in layoutFragment.textAttachmentViewProviders {
                if provider.textAttachment == attachment {
                    return provider.view
                }
            }
        }

        return nil
    }

    /// Forces a layout update for all attachment views.
    /// This can be useful when attachment content has changed and needs to be redrawn.
    func invalidateAttachmentViews() {
        for fragmentView in contentViewportView.subviews.compactMap({ $0 as? STTextLayoutFragmentView }) {
            fragmentView.needsLayout = true
            fragmentView.needsDisplay = true
        }
    }

    // MARK: - Attachment Selection

    /// Selects the text attachment at the specified location.
    /// - Parameter location: The location of the attachment to select.
    /// - Returns: true if the attachment was successfully selected, false otherwise.
    @discardableResult
    func selectAttachment(at location: NSTextLocation) -> Bool {
        guard let attachmentRange = textAttachmentRange(at: location) else {
            return false
        }

        // Select the attachment range
        setSelectedTextRange(attachmentRange, updateLayout: true)
        return true
    }

    /// Selects the specified text attachment.
    /// - Parameter attachment: The attachment to select.
    /// - Returns: true if the attachment was successfully selected, false otherwise.
    @discardableResult
    func selectAttachment(_ attachment: NSTextAttachment) -> Bool {
        // Find the attachment in the document
        let attachments = textAttachments()
        for (attachmentInfo) in attachments {
            if attachmentInfo.attachment == attachment {
                setSelectedTextRange(attachmentInfo.range, updateLayout: true)
                return true
            }
        }
        return false
    }
}
