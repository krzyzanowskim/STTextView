//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

final class STTextInputTokenizer: NSObject, UITextInputTokenizer {
    weak var textLayoutManager: NSTextLayoutManager?

    init(_ textLayoutManager: NSTextLayoutManager) {
        self.textLayoutManager = textLayoutManager
    }

    func rangeEnclosingPosition(
        _ position: UITextPosition,
        with granularity: UITextGranularity,
        inDirection direction: UITextDirection
    ) -> UITextRange? {
        guard let textLayoutManager = self.textLayoutManager,
              let position = position as? STTextLocation
        else {
            return nil
        }

        switch granularity {
        case .character, .line, .paragraph, .sentence, .word:
            let positionSelection = NSTextSelection(position.location, affinity: direction == .storage(.backward) ? .downstream : .upstream)
            let destination = textLayoutManager.textSelectionNavigation.textSelection(
                for: granularity.textSelectionGranularity,
                enclosing: positionSelection
            )

            if destination.granularity != granularity.textSelectionGranularity {
                return nil
            }

            return destination.textRanges.first?.uiTextRange
        case .document:
            return textLayoutManager.documentRange.uiTextRange
        @unknown default:
            assertionFailure()
            return nil
        }
    }

    func position(
        from position: UITextPosition,
        toBoundary granularity: UITextGranularity,
        inDirection direction: UITextDirection
    ) -> UITextPosition? {
        guard let textLayoutManager = self.textLayoutManager,
              let position = position as? STTextLocation
        else {
            return nil
        }

        let positionSelection = NSTextSelection(position.location, affinity: .downstream)
        let destination = textLayoutManager.textSelectionNavigation.destinationSelection(
            for: positionSelection,
            direction: direction.textSelectionNavigationDirection,
            destination: granularity.textSelectionDestination,
            extending: false,
            confined: false
        )

        return destination?.textRanges.first?.location.uiTextPosition
    }

    func isPosition(
        _ position: UITextPosition,
        atBoundary granularity: UITextGranularity,
        inDirection direction: UITextDirection
    ) -> Bool {
        guard let textLayoutManager = self.textLayoutManager,
              let position = position as? STTextLocation
        else {
            return false
        }

        var r: UITextRange? {
            switch granularity {
            case .character, .line, .paragraph, .sentence, .word:
                let positionSelection = NSTextSelection(position.location, affinity: .downstream)
                let destination = textLayoutManager.textSelectionNavigation.textSelection(
                    for: granularity.textSelectionGranularity,
                    enclosing: positionSelection
                )

                if destination.granularity != granularity.textSelectionGranularity {
                    return nil
                }

                return destination.textRanges.first?.uiTextRange
            case .document:
                return textLayoutManager.documentRange.uiTextRange
            @unknown default:
                assertionFailure()
                return nil
            }
        }

        guard let r else {
            return false
        }

        return r.start == position || r.end == position
    }

    func isPosition(
        _ position: UITextPosition,
        withinTextUnit granularity: UITextGranularity,
        inDirection direction: UITextDirection
    ) -> Bool {
        guard let textLayoutManager = self.textLayoutManager,
              let position = position as? STTextLocation
        else {
            return false
        }

        var r: UITextRange? {
            switch granularity {
            case .character, .line, .paragraph, .sentence, .word:
                let positionSelection = NSTextSelection(position.location, affinity: .upstream)
                let destination = textLayoutManager.textSelectionNavigation.textSelection(
                    for: granularity.textSelectionGranularity,
                    enclosing: positionSelection
                )
                return destination.textRanges.first?.uiTextRange
            case .document:
                return textLayoutManager.documentRange.uiTextRange
            @unknown default:
                assertionFailure()
                return nil
            }
        }

        guard let r else {
            return false
        }

        return r.nsTextRange.contains(position.location)
    }

}

// MARK: -

private extension UITextGranularity {

    var textSelectionGranularity: NSTextSelection.Granularity {
        switch self {
        case .character:
            return .character
        case .line:
            return .line
        case .paragraph:
            return .paragraph
        case .sentence:
            return .sentence
        case .word:
            return .word
        case .document:
            assertionFailure("Invalid use")
            return .character
        @unknown default:
            assertionFailure()
            return .character
        }
    }

    var textSelectionDestination: NSTextSelectionNavigation.Destination {
        switch self {
        case .character:
            return .character
        case .line:
            return .line
        case .paragraph:
            return .paragraph
        case .sentence:
            return .sentence
        case .word:
            return .word
        case .document:
            return .document
        @unknown default:
            return .character
        }
    }
}
