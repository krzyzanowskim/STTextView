//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

public struct STPluginContext<P: STPlugin> {
    public let coordinator: P.Coordinator
    public let textView: STTextView

    init(coordinator: P.Coordinator, textView: STTextView) {
        self.coordinator = coordinator
        self.textView = textView
    }
}
