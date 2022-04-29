import Foundation

final class CoalescingUndoManager<T>: UndoManager {

    private(set) var coalescing: (value: T?, action: ((T) -> Void)?)?

    private var coalescingIsUndoing: Bool = false
    private var coalescingIsRedoing: Bool = false

    var isCoalescing: Bool {
        coalescing != nil
    }

    func breakUndoCoalescing() {
        coalescing = nil
    }

    func coalesce(_ value: T) {
        guard isUndoRegistrationEnabled else { return}
        coalescing = (value: value, action: coalescing?.action)
    }

    func registerCoalescingUndo<Target>(withTarget target: Target, _ action: @escaping (Target, T) -> Void) where Target: AnyObject {
        guard isUndoRegistrationEnabled else { return }
        coalescing = (value: coalescing?.value, action: { action(target, $0) })
    }

    override var canUndo: Bool {
        super.canUndo || isCoalescing
    }

    override var isUndoing: Bool {
        super.isUndoing || coalescingIsUndoing
    }

    override var isRedoing: Bool {
        super.isRedoing || coalescingIsRedoing
    }

    override func undo() {
        if let action = coalescing?.action, let value = coalescing?.value {
            coalescingIsUndoing = true
            action(value)
            breakUndoCoalescing()
            coalescingIsUndoing = false
        } else {
            super.undo()
        }
    }

    override func redo() {
        // TODO: coalescing redo
        // Doesn't work. `super.undo()` put action on redo stack,
        // what we can't do here since that's private stack.
        // We should manage our redo stack just for clalescing action.
        // but that's for another day.
        super.redo()
    }

    override var undoMenuItemTitle: String {
        if canUndo {
            return super.undoMenuItemTitle
        } else {
            return NSLocalizedString("Undo", comment: "Undo")
        }
    }

    override var redoMenuItemTitle: String {
        if canRedo {
            return super.redoMenuItemTitle
        } else {
            return NSLocalizedString("Redo", comment: "Redo")
        }
    }
}
