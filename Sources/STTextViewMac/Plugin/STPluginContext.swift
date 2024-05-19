//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

@MainActor
public protocol PluginContext<Plugin> {
    associatedtype Plugin: STPlugin
    var coordinator: Plugin.Coordinator { get }
    var textView: STTextView { get }
    var events: STPluginEvents { get }
}

public struct STPluginContext<Plugin: STPlugin>: PluginContext {
    public let coordinator: Plugin.Coordinator
    public let textView: STTextView
    public let events: STPluginEvents

    init(coordinator: Plugin.Coordinator, textView: STTextView, events: STPluginEvents) {
        self.coordinator = coordinator
        self.textView = textView
        self.events = events
    }
}

public struct STPluginCoordinatorContext {
    public let textView: STTextView

    init(textView: STTextView) {
        self.textView = textView
    }
}
