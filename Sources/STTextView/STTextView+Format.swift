//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Adds the underline attribute to the selected text attributes if absent; removes the attribute if present.
    ///
    /// If there is a selection and the first character of the selected range has any form of underline on it,
    /// or if there is no selection and the typing attributes have any form of underline, then underline is removed;
    /// otherwise a single simple underline is added.
    @objc open func underline(_ sender: Any?) {
        guard isEditable else {
            return
        }

        let selectionRanges = textLayoutManager.textSelections.flatMap(\.textRanges).filter({ !$0.isEmpty })

        // If there is a selection and
        // the first character of the selected range
        // has any form of underline on it
        // then underline is removed
        if let location = selectionRanges.first?.location,
           textContentManager.attributes(at: location).contains(where: { $0.key == .underlineStyle })
        {
            for textRange in selectionRanges {
                removeAttribute(.underlineStyle, range: textRange)
                removeAttribute(.underlineColor, range: textRange)
            }
        } else if selectionRanges.isEmpty, typingAttributes.contains(where: { $0.key == .underlineStyle }) {
            // or if there is no selection and the typing attributes have any form of underline
            for textRange in selectionRanges {
                removeAttribute(.underlineStyle, range: textRange)
                removeAttribute(.underlineColor, range: textRange)
            }
        } else {
            // otherwise a single simple underline is added
            for textRange in selectionRanges {
                addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue], range: textRange)
            }
        }
    }
}
