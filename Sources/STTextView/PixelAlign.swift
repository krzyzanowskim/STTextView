//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import CoreGraphics
import Foundation

extension CGRect {
    var pixelAligned: CGRect {
        NSIntegralRectWithOptions(self, .alignAllEdgesNearest)
    }
}
