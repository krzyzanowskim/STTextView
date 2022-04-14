//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Cocoa

extension STTextView {

    @objc func performFindPanelAction(_ sender: Any?) {
        performTextFinderAction(sender)
    }

    @objc open override func performTextFinderAction(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else {
            assertionFailure("Unexpected caller")
            return
        }


        textFinder.performAction(NSTextFinder.Action(rawValue: menuItem.tag)!)
    }
    
}
