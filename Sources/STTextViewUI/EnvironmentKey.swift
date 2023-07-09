//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa
import SwiftUI

private struct FontEnvironmentKey: EnvironmentKey {
    static var defaultValue: NSFont = .preferredFont(forTextStyle: .body)
}

public extension EnvironmentValues {
    var font: NSFont {
        get { self[FontEnvironmentKey.self] }
        set { self[FontEnvironmentKey.self] = newValue }
    }
}


