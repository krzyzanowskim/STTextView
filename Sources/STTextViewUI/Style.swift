//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import SwiftUI

public protocol TextViewModifier: SwiftUI.View { }

extension STTextViewUI.TextView: TextViewModifier {

    public struct EnvironmentModifier<Content: View, V>: View, TextViewModifier {
        private let content: Content
        private let keyPath: WritableKeyPath<EnvironmentValues, V>
        private let value: V

        init(content: Content, keyPath: WritableKeyPath<EnvironmentValues, V>, value: V) {
            self.content = content
            self.keyPath = keyPath
            self.value = value
        }

        public var body: some View {
            content
                .environment(keyPath, value)
        }
    }

}

extension TextViewModifier {
    public func textViewFont(_ font: NSFont) -> TextView.EnvironmentModifier<Self, NSFont> {
        TextView.EnvironmentModifier(content: self, keyPath: \.font, value: font)
    }
}
