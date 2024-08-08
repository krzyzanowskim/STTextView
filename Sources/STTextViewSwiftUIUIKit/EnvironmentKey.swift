//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI

private struct FontEnvironmentKey: EnvironmentKey {
    static var defaultValue: UIFont = .preferredFont(forTextStyle: .body)
}

internal extension EnvironmentValues {
    var font: UIFont {
        get { self[FontEnvironmentKey.self] }
        set { self[FontEnvironmentKey.self] = newValue }
    }
}


