//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import UIKit

class STTextViewDelegateProxy: NSObject, STTextViewDelegate {
    weak var source: (any STTextViewDelegate)?

    init(source: STTextViewDelegate?) {
        self.source = source
    }

    func undoManager(for textView: STTextView) -> UndoManager? {
        source?.undoManager(for: textView)
    }

    func textViewWillChangeText(_ notification: Notification) {
        source?.textViewWillChangeText(notification)
    }

    func textViewDidChangeText(_ notification: Notification) {
        source?.textViewDidChangeText(notification)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        source?.textViewDidChangeSelection(notification)
    }

    func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        var result = source?.textView(textView, shouldChangeTextIn: affectedCharRange, replacementString: replacementString) ?? true
        result = result && textView.plugins.events.reduce(result) { partialResult, events in
            partialResult && events.shouldChangeTextHandler?(affectedCharRange, replacementString) ?? true
        }
        return result
    }

    func textView(_ textView: STTextView, willChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        source?.textView(textView, willChangeTextIn: affectedCharRange, replacementString: replacementString)

        for events in textView.plugins.events {
            events.willChangeTextHandler?(affectedCharRange)
        }
    }

    func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        source?.textView(textView, didChangeTextIn: affectedCharRange, replacementString: replacementString)

        for events in textView.plugins.events {
            events.didChangeTextHandler?(affectedCharRange, replacementString)
        }

    }

    func textView(_ textView: STTextView, clickedOnLink link: Any, at location: any NSTextLocation) -> Bool {
        source?.textView(textView, clickedOnLink: link, at: location) ?? false
    }

}
