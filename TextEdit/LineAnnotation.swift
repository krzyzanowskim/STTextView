//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import STTextView
import Cocoa

final class LineAnnotation: STLineAnnotation {
    let message: String

    init(message: String, location: NSTextLocation) {
        self.message = message
        super.init(location: location)
    }
}
