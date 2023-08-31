//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

public class STPluginEvents {

    public typealias ShouldChangeTextHandler = @MainActor (_ affectedCharRange: NSTextRange, _ replacementString: String?) -> Bool

    var willChangeTextHandler: ((_ affectedRange: NSTextRange) -> Void)?
    var didChangeTextHandler: ((_ affectedRange: NSTextRange, _ replacementString: String?) -> Void)?
    var shouldChangeTextHandler: ShouldChangeTextHandler?
    var onContextMenuHandler: ((_ location: NSTextLocation, _ contentManager: NSTextContentManager) -> NSMenu)?
    var didLayoutViewportHandler: ((_ visibleRange: NSTextRange?) -> Void)?

    @discardableResult
    public func onWillChangeText(_ handler: @escaping (_ affectedRange: NSTextRange) -> Void) -> Self {
        willChangeTextHandler = handler
        return self
    }

    @discardableResult
    public func onDidChangeText(_ handler: @escaping (_ affectedRange: NSTextRange, _ replacementString: String?) -> Void) -> Self {
        didChangeTextHandler = handler
        return self
    }

    @discardableResult
    public func shouldChangeText(_ handler: @escaping ShouldChangeTextHandler) -> Self {
        shouldChangeTextHandler = handler
        return self
    }

    @discardableResult
    public func onContextMenu(_ handler: @escaping (_ location: NSTextLocation, _ contentManager: NSTextContentManager) -> NSMenu) -> Self {
        onContextMenuHandler = handler
        return self
    }

    @discardableResult
    public func onDidLayoutViewport(_ handler: @escaping (_ visibleRange: NSTextRange?) -> Void) -> Self {
        didLayoutViewportHandler = handler
        return self
    }
}

extension Array<(plugin: STPlugin, events: STPluginEvents?)> {
    var events: [STPluginEvents] {
        compactMap({ $0.events })
    }
}
