//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

struct Plugin {
    let instance: any STPlugin
    var events: STPluginEvents?

    /// Whether plugin is already setup
    var isSetup: Bool {
        events != nil
    }
}

extension [Plugin] {
    var events: [STPluginEvents] {
        compactMap(\.events)
    }
}
