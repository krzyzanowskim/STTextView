//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI

public protocol TextViewModifier: SwiftUI.View {}

public extension TextViewModifier {

    /// Sets the default font for text in this view.
    func textViewFont(_ font: NSFont) -> TextViewEnvironmentModifier<Self, NSFont> {
        TextViewEnvironmentModifier(content: self, keyPath: \.font, value: font)
    }

    /// Sets the line height multiple for text in this view.
    /// - Parameter multiple: The line height multiple. Values greater than 1.0 increase line spacing.
    func textViewLineHeightMultiple(_ multiple: CGFloat) -> TextViewEnvironmentModifier<Self, CGFloat> {
        TextViewEnvironmentModifier(content: self, keyPath: \.lineHeightMultiple, value: multiple)
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
    static var defaultValue: NSFont = .preferredFont(forTextStyle: .body)
}

private struct LineHeightMultipleEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var font: NSFont {
        get { self[FontEnvironmentKey.self] }
        set { self[FontEnvironmentKey.self] = newValue }
    }

    var lineHeightMultiple: CGFloat {
        get { self[LineHeightMultipleEnvironmentKey.self] }
        set { self[LineHeightMultipleEnvironmentKey.self] = newValue }
    }
}
