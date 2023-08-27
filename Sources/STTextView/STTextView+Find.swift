//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    /// Performs a find panel action specified by the sender's tag.
    ///
    /// This is the generic action method for the find menu and find panel, and can be overridden to implement a custom find panel.
    /// See NSTextFinder.Action for list of possible tags
    @objc open func performFindPanelAction(_ sender: Any?) {
        performTextFinderAction(sender)
    }

    /// Performs all find oriented actions.
    /// Before OS X v10.7, the default action for these menu items was performFindPanelAction(_:)
    @objc open override func performTextFinderAction(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
              let action = NSTextFinder.Action(rawValue: menuItem.tag)
        else {
            assertionFailure("Unexpected caller")
            return
        }

        if textFinder.validateAction(action) {
            textFinder.performAction(action)
        }
    }
    
}
