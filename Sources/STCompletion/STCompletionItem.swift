//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

public protocol STCompletionItem: Identifiable {
    var view: NSView { get }
}
