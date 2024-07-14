//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

extension NSTextLayoutManager {

    func destinationSelection(
        from originTextSelection: NSTextSelection,
        in direction: NSTextSelectionNavigation.Direction,
        offset: Int
    ) -> NSTextSelection? {
        guard offset > 0 else {
            return originTextSelection
        }
        let result = textSelectionNavigation.destinationSelection(
            for: originTextSelection,
            direction: direction,
            destination: .character,
            extending: false,
            confined: false
        )
        guard let result else {
            return nil
        }
        return destinationSelection(
            from: result,
            in: direction,
            offset: offset - 1
        )
    }

}
