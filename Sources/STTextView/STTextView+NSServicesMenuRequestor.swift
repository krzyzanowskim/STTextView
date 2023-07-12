//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa
import UniformTypeIdentifiers

extension STTextView: NSServicesMenuRequestor {

    @objc open func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {

        if type == .string,
           pboard.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier]),
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

        if type == .rtf,
           pboard.canReadItem(withDataConformingToTypes: [UTType.rtf.identifier]),
           let attributedString = pboard.readObjects(forClasses: [NSAttributedString.self])?.first as? NSAttributedString
        {
            replaceCharacters(
                in: textLayoutManager.textSelections.flatMap(\.textRanges),
                with: attributedString,
                allowsTypingCoalescing: false
            )
            return true
        }

        return false
    }

    @objc open func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        if types.isEmpty, textLayoutManager.textSelections.isEmpty {
            return false
        }

        guard let attributedString = textLayoutManager.textSelectionsAttributedString() else {
            return false
        }

        let actions = types.map { type -> () -> Bool in
            switch type {
            case .string:
                return {
                    pboard.setString(attributedString.string, forType: .string)
                }
            case .rtf:
                return {
                    let rtf = attributedString.rtf(from: NSRange(location: 0, length: attributedString.length))
                    return pboard.setData(rtf, forType: .rtf)
                }
            case .rtfd:
                return {
                    let rtfd = attributedString.rtfd(from: NSRange(location: 0, length: attributedString.length))
                    return pboard.setData(rtfd, forType: .rtfd)
                }
            default:
                return { false }
            }
        }

        if !actions.isEmpty {
            pboard.clearContents()

        }

        return actions.reduce(false) { partialResult, action in
            partialResult || action()
        }
    }
}
