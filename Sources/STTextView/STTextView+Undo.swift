//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

// NSResponder.undoManager doesn work out of the box (as 03.2022, macOS 12.3)
// see https://gist.github.com/krzyzanowskim/1a13f27e6b469ca2ffcf9b53588b837a

extension STTextView {

    open override var undoManager: UndoManager? {
        allowsUndo ? _undoManager : nil
    }

    @objc func undo(_ sender: AnyObject?) {
        undoManager?.undo()
    }

    @objc func redo(_ sender: AnyObject?) {
        undoManager?.redo()
    }

}

extension STTextView: NSMenuItemValidation {

    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        validateUserInterfaceItem(menuItem)
    }

}

extension STTextView: NSUserInterfaceValidations {

    public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(undo(_:)) {
            let result = allowsUndo ? undoManager?.canUndo ?? false : false

            // NSWindow does that like this, here (as debugged)
            if let undoManager = undoManager {
                (item as? NSMenuItem)?.title = undoManager.undoMenuItemTitle
            }

            return result
        } else if item.action == #selector(redo(_:)) {
            let result = allowsUndo ? undoManager?.canRedo ?? false : false

            // NSWindow does that like this, here (as debugged)
            if let undoManager = undoManager {
                (item as? NSMenuItem)?.title = undoManager.redoMenuItemTitle
            }
            return result
        }

        return true
    }

}
