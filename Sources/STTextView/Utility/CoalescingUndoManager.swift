import Foundation

final class CoalescingUndoManager<T>: UndoManager {

    private(set) var coalescing: (value: T?, action: ((T) -> Void)?)?

    private var coalescingIsUndoing: Bool = false
    private var coalescingIsRedoing: Bool = false

    var isCoalescing: Bool {
        coalescing != nil
    }

    func breakCoalescing() {
        coalescing = nil
    }

    override init() {
        super.init()
        self.runLoopModes = [.default, .common, .eventTracking, .modalPanel]
    }

    func coalesce(_ value: T) {
        guard isUndoRegistrationEnabled else {
            return
        }

        assert(isCoalescing, "Coalescing not started. Call startCoalescing(withTarget:_) first")

        coalescing = (value: value, action: coalescing?.action)
        return
    }

    func startCoalescing<Target>(_ value: T, withTarget target: Target, _ action: @escaping (Target, T) -> Void) where Target: AnyObject {
        guard isUndoRegistrationEnabled else { return }
        coalescing = (value: value, action: { action(target, $0) })
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
            breakCoalescing()
            coalescingIsUndoing = false
        } else {
            super.undo()
        }
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
