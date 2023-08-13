import Foundation
import AppKit
import OSLog
import STTextView

public struct DummyPlugin: STPlugin {
    public init() {

    }

    public func setUp(context: Context) {
        context.events.onWillChangeText(willChangeText)
        context.events.onDidChangeText(didChangeText)
        context.events.shouldChangeText(shouldChangeText)
    }

    private func willChangeText() {
        print("will change handler!")
    }

    private func didChangeText() {
        print("did change handler!")
    }

    private func shouldChangeText(in textRange: NSTextRange, replacementString: String?) -> Bool {
        true
    }
    
}
