//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

public class STPluginEvents {

    var willChangeTextHandler: (() -> Void)?
    var didChangeTextHandler: (() -> Void)?
    var shouldChangeTextHandler: ((_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool)?
    var onContextMenuHandler: ((_ location: NSTextLocation, _ contentManager: NSTextContentManager) -> NSMenu)?

    @discardableResult
    public func onWillChangeText(_ handler: @escaping () -> Void) -> Self {
        willChangeTextHandler = handler
        return self
    }

    @discardableResult
    public func onDidChangeText(_ handler: @escaping () -> Void) -> Self {
        didChangeTextHandler = handler
        return self
    }

    @discardableResult
    public func shouldChangeText(_ handler: @escaping (_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool) -> Self {
        shouldChangeTextHandler = handler
        return self
    }

    @discardableResult
    public func onContextMenu(_ handler: @escaping (_ location: NSTextLocation, _ contentManager: NSTextContentManager) -> NSMenu) -> Self {
        onContextMenuHandler = handler
        return self
    }

}
