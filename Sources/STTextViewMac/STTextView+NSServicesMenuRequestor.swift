//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

// On a Swift type level "NSPasteboardType.string = NSPasteboard.PasteboardType.string"
// that's not necessarily what is received. We receive old (deprecated) values that
// uses different raw string representation (NSStringPboardType, ...).
// That value hast to be handled to properly interact with other apps.
// https://twitter.com/krzyzanowskim/status/1679442783759659009

import AppKit
import UniformTypeIdentifiers

extension STTextView: NSServicesMenuRequestor {

    /// The types this text view can read immediately from the pasteboard.
    @objc open var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        [.string, .init(rawValue: "NSStringPboardType"), .rtf, .init(rawValue: "NSRTFPboardType")]
    }

    /// The pasteboard types that can be provided from the current selection.
    @objc open var writablePasteboardTypes: [NSPasteboard.PasteboardType] {
        [.string, .init(rawValue: "NSStringPboardType"), .rtf, .init(rawValue: "NSRTFPboardType")]
    }

    /// Reads data of the given type from the specified pasteboard.
    @objc open func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {

        switch type.rawValue {
        case NSPasteboard.PasteboardType.string.rawValue, "NSStringPboardType":
            if pboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]),
                let string = pboard.string(forType: type)
            {
                replaceCharacters(
                    in: textLayoutManager.textSelections.flatMap(\.textRanges),
                    with: string,
                    useTypingAttributes: true,
                    allowsTypingCoalescing: false
                )
                return true
            }
        case NSPasteboard.PasteboardType.rtf.rawValue, "NSRTFPboardType":
            if pboard.canReadItem(withDataConformingToTypes: [UTType.rtf.identifier]),
               let attributedString = pboard.readObjects(forClasses: [NSAttributedString.self])?.first as? NSAttributedString
            {
                replaceCharacters(
                    in: textLayoutManager.textSelections.flatMap(\.textRanges),
                    with: attributedString,
                    allowsTypingCoalescing: false
                )
                return true
            }
        default:
            return false
        }

        return false
    }

    /// Writes the current selection to the specified pasteboard under each given type.
    @objc open func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        if types.isEmpty || textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty {
            return false
        }

        guard let attributedString = textLayoutManager.textSelectionsAttributedString() else {
            return false
        }

        let actions = types.map { type -> () -> Bool in
            switch type.rawValue {
            case NSPasteboard.PasteboardType.string.rawValue, "NSStringPboardType":
                return {
                    pboard.setString(attributedString.string, forType: .string)
                }
            case NSPasteboard.PasteboardType.rtf.rawValue, "NSRTFPboardType":
                return {
                    let rtf = attributedString.rtf(from: NSRange(location: 0, length: attributedString.length))
                    return pboard.setData(rtf, forType: .rtf)
                }
            default:
                return { false }
            }
        }

        if !actions.isEmpty {
            pboard.clearContents()
        }

        return actions.reduce(false) { partialResult, action in
            let res = action()
            return partialResult || res
        }
    }

    /// Returns `self` if the text view can provide and accept the specified data types, or nil if it can't
    @objc open override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        var sendOK = false
        var returnOK = false

        if sendType == nil {
            sendOK = true
        } else if !selectedRange().isEmpty, (sendType == .string || sendType?.rawValue == "NSStringPboardType" || sendType == .rtf || sendType?.rawValue == "NSRTFPboardType") {
            sendOK = true
        }

        if returnType == nil {
            returnOK = true
        } else if isEditable, (returnType == .string || returnType?.rawValue == "NSStringPboardType" || returnType == .rtf || returnType?.rawValue == "NSRTFPboardType") {
            returnOK = true
        }

        if sendOK || returnOK {
            return self
        }

        return self.nextResponder?.validRequestor(forSendType: sendType, returnType: returnType)
    }
}
