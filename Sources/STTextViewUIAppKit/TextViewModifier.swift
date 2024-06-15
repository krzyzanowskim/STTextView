//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI

public protocol TextViewModifier: SwiftUI.View { }

extension STTextViewUIAppKit.TextView: TextViewModifier {

    public struct EnvironmentModifier<Content: View, V>: View, TextViewModifier {
        let content: Content
        let keyPath: WritableKeyPath<EnvironmentValues, V>
        let value: V

        public var body: some View {
            content
                .environment(keyPath, value)
        }
    }

}

extension TextViewModifier {

    /// Sets the default font for text in this view.
    public func textViewFont(_ font: NSFont) -> TextView.EnvironmentModifier<Self, NSFont> {
        TextView.EnvironmentModifier(content: self, keyPath: \.font, value: font)
    }
}
