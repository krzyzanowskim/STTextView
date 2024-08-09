//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI

public protocol TextViewModifier: SwiftUI.View { }

extension TextViewModifier {

    /// Sets the default font for text in this view.
    public func textViewFont(_ font: UIFont) -> TextViewEnvironmentModifier<Self, UIFont> {
        TextViewEnvironmentModifier(content: self, keyPath: \.font, value: font)
    }
}

public struct TextViewEnvironmentModifier<Content: View, V>: View, TextViewModifier {
    let content: Content
    let keyPath: WritableKeyPath<EnvironmentValues, V>
    let value: V

    public var body: some View {
        content
            .environment(keyPath, value)
    }
}

private struct FontEnvironmentKey: EnvironmentKey {
    static var defaultValue: UIFont = .preferredFont(forTextStyle: .body)
}

internal extension EnvironmentValues {
    var font: UIFont {
        get { self[FontEnvironmentKey.self] }
        set { self[FontEnvironmentKey.self] = newValue }
    }
}
