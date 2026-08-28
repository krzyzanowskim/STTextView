//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

/// An opaque handle to an installed plugin.
///
/// ``STTextView/addPlugin(_:id:)`` returns one. Plugins are values and cannot be
/// compared by identity, so this handle is the only way to refer to an
/// installation afterwards - pass it to ``STTextView/removePlugin(_:)``.
///
/// Use ``init()`` for a fresh unique handle, or ``init(_:)`` to name a slot the
/// caller wants to address later without storing the handle:
///
/// ```swift
/// let formatting = STPluginIdentifier("textFormatting")
/// textView.removePlugin(formatting)
/// textView.addPlugin(MyFormattingPlugin(), id: formatting)
/// ```
public struct STPluginIdentifier: Hashable, Sendable {
    private let rawValue: String

    /// Creates a handle that is unique to a single installation.
    public init() {
        self.rawValue = UUID().uuidString
    }

    /// Creates a stable handle from a caller-chosen name.
    ///
    /// Names are only meaningful to the caller that chose them; two unrelated
    /// callers picking the same name will refer to the same slot.
    public init(_ name: String) {
        self.rawValue = name
    }
}

struct Plugin: Identifiable {
    let id: STPluginIdentifier
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
