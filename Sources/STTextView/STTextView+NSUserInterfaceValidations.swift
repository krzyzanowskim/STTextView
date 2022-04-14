//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView: NSMenuItemValidation {

    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        validateUserInterfaceItem(menuItem)
    }

}

extension STTextView: NSUserInterfaceValidations {

    public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(undo(_:)):
            let result = allowsUndo ? undoManager?.canUndo ?? false : false

            // NSWindow does that like this, here (as debugged)
            if let undoManager = undoManager {
                (item as? NSMenuItem)?.title = undoManager.undoMenuItemTitle
            }

            return result
        case #selector(redo(_:)):
            let result = allowsUndo ? undoManager?.canRedo ?? false : false

            // NSWindow does that like this, here (as debugged)
            if let undoManager = undoManager {
                (item as? NSMenuItem)?.title = undoManager.redoMenuItemTitle
            }
            return result
        case #selector(performFindPanelAction(_:)), #selector(performTextFinderAction(_:)):
            return textFinder.validateAction(NSTextFinder.Action(rawValue: item.tag)!)
        default:
            return true
        }
    }

}
