//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

extension STTextView {

    /// Yanking means reinserting text previously killed. The usual way to move or copy text is to kill it and then yank it elsewhere.
    ///
    /// https://www.gnu.org/software/emacs/manual/html_node/emacs/Yanking.html
    open override func yank(_ sender: Any?) {
        replaceCharacters(
            in: textLayoutManager.insertionPointSelections.flatMap(\.textRanges),
            with: _yankingManager.yank(),
            useTypingAttributes: true,
            allowsTypingCoalescing: false
        )
    }

}
