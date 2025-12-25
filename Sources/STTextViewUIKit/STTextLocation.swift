//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import UIKit

class STTextLocation: UITextPosition {
    let location: NSTextLocation

    override var debugDescription: String {
        location.description
    }

    init(location: NSTextLocation) {
        self.location = location
    }
}

extension NSTextLocation {
    var uiTextPosition: STTextLocation {
        STTextLocation(location: self)
    }
}
