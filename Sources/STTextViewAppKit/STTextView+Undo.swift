//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

// NSResponder.undoManager doesn't work out of the box (as 03.2022, macOS 12.3)
// see https://gist.github.com/krzyzanowskim/1a13f27e6b469ca2ffcf9b53588b837a

extension STTextView {

    open override var undoManager: UndoManager? {
        guard allowsUndo else {
            return nil
        }

        return delegateProxy.undoManager(for: self) ?? _undoManager
    }

    @objc func undo(_ sender: AnyObject?) {
        if allowsUndo {
            undoManager?.undo()
        }
    }

    @objc func redo(_ sender: AnyObject?) {
        if allowsUndo {
            undoManager?.redo()
        }
    }

}
