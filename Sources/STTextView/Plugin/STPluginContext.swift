//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

public struct STPluginContext<P: STPlugin> {
    public let coordinator: P.Coordinator
    public let textView: STTextView
    public var events: STPluginEvents

    init(coordinator: P.Coordinator, textView: STTextView) {
        self.coordinator = coordinator
        self.textView = textView
        self.events = STPluginEvents()
    }
}

public class STPluginEvents {

    private var willChangeTextHandler: (() -> Void)?
    private var didChangeTextHandler: (() -> Void)?

    public func onWillChangeText(_ handler: @escaping () -> Void) {
        willChangeTextHandler = handler
    }

    public func onDidChangeText(_ handler: @escaping () -> Void) {
        didChangeTextHandler = handler
    }

}

