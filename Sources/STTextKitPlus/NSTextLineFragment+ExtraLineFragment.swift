//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

public extension NSTextLineFragment {

    var isExtraLineFragment: Bool {
        // textLineFragment.characterRange.isEmpty the extra line fragment at the end of a document.
        characterRange.isEmpty
    }

}
