import Foundation

final class CoalescingUndoManager: UndoManager {

    private(set) var coalescing: (value: TypingTextUndo?, undoAction: ((TypingTextUndo) -> Void)?)?

    private var coalescingIsUndoing: Bool = false
    private var coalescingIsRedoing: Bool = false

    var isCoalescing: Bool {
        coalescing != nil
    }

    func breakCoalescing() {
        // register undo and break coalescing
        if !isUndoing, !isRedoing, let undoAction = coalescing?.undoAction, let value = coalescing?.value {
            // Disable implicit grouping to avoid group coalescing and non-coalescing undo
            groupsByEvent = false
            beginUndoGrouping()
            registerUndo(withTarget: self) { _ in
                undoAction(value)
            }
            endUndoGrouping()
            groupsByEvent = true
        }

        coalescing = nil
    }

    override init() {
        super.init()
        self.runLoopModes = [.default, .common, .eventTracking, .modalPanel]
    }

    func coalesce(_ value: TypingTextUndo) {
        guard isUndoRegistrationEnabled else {
            return
        }

        assert(isCoalescing, "Coalescing not started. Call startCoalescing(withTarget:_) first")

        coalescing = (value: value, undoAction: coalescing?.undoAction)
        return
    }

    func startCoalescing<Target>(_ value: TypingTextUndo, withTarget target: Target, _ undoAction: @escaping (Target, TypingTextUndo) -> Void) where Target: AnyObject {
        guard isUndoRegistrationEnabled else { return }
        coalescing = (value: value, undoAction: { undoAction(target, $0) })
    }

    override var canRedo: Bool {
        super.canRedo
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
        if let undoAction = coalescing?.undoAction, let value = coalescing?.value {
            coalescingIsUndoing = true
            undoAction(value)
            breakCoalescing()
            coalescingIsUndoing = false
            // FIXME: call undo to register redo
            // When the Undo system performs an undo action,
            // it expects me to register the redo actions using the same code as for undo.
            // That makes the coalescing flow tricky to make right right now
        } else {
            super.undo()
        }
    }

    override func redo() {
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
