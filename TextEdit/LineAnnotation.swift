//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import STTextView
import AppKit

final class LineAnnotation: STLineAnnotation {
    let message: AttributedString

    init(message: AttributedString, location: NSTextLocation) {
        self.message = message
        super.init(location: location)
    }
}
