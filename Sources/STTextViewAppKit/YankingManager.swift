//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

/// Yanking means reinserting text previously killed. The usual way to move or copy text is to kill it and then yank it elsewhere.
/// https://www.gnu.org/software/emacs/manual/html_node/emacs/Yanking.html
final class YankingManager {

    enum DeleteAction {
        case delete
        case deleteToMark
        case deleteWordForward
        case deleteWordBackward
        case deleteToBeginningOfLine
        case deleteToEndOfLine
        case deleteToBeginningOfParagraph
        case deleteToEndOfParagraph
    }

    private var index: Int = 0
    private var buffer: [String]
    private var yanking: Bool = false
    private var lastDeleteAction: DeleteAction?

    init() {
        let killRingSize = UserDefaults.standard.integer(forKey: "NSTextKillRingSize")
        buffer = Array(repeating: "", count: max(killRingSize, 1))
    }

    /// Call when selection changes in editor
    func selectionChanged() {
        lastDeleteAction = nil
    }

    /// Call when text changes in editor
    func textChanged() {
        yanking = false
        lastDeleteAction = nil
    }

    /// Call when text editor performs any of the defined Actions.
    /// The editor should perform all selection and buffer mutations within the `killBlock`.
    func kill(action: DeleteAction, string: String) {
        let savedLastAction = lastDeleteAction

        if action != savedLastAction {
            lastDeleteAction = action

            if index == buffer.count - 1 {
                index = 0
            } else {
                index += 1
            }

            buffer[index] = ""
        } else {
            self.lastDeleteAction = savedLastAction
        }

        switch action {
        case .delete:
            buffer[index] = string
        case .deleteToBeginningOfLine, .deleteToBeginningOfParagraph, .deleteWordBackward:
            buffer[index] = string + buffer[index]
        case .deleteToEndOfLine, .deleteToEndOfParagraph, .deleteWordForward, .deleteToMark:
            buffer[index] = buffer[index] + string
        }
    }

    /// Call in response to `yank:` action.
    func yank() -> String {
        yanking = true
        return buffer[index]
    }

    /// Call in response to `yankAndSelect:` action.
    func yankAndSelect() -> String {
        if yanking {
            if index == 0 {
                index = buffer.count - 1
            } else {
                index -= 1
            }
        }
        yanking = true
        return buffer[index]
    }

}
