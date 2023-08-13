//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

public class STPluginEvents {

    var willChangeTextHandler: (() -> Void)?
    var didChangeTextHandler: (() -> Void)?
    var shouldChangeText: ((_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool)?

    public func onWillChangeText(_ handler: @escaping () -> Void) {
        willChangeTextHandler = handler
    }

    public func onDidChangeText(_ handler: @escaping () -> Void) {
        didChangeTextHandler = handler
    }

    public func shouldChangeText(_ handler: @escaping (_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool) {
        shouldChangeText = handler
    }

}
