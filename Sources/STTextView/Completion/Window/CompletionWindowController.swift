import Cocoa

internal final class CompletionWindowController: NSWindowController {

    weak var delegate: CompletionWindowDelegate?

    private var completionViewController: STCompletionViewControllerProtocol {
        window!.contentViewController as! STCompletionViewControllerProtocol
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    init(_ viewController: some STCompletionViewControllerProtocol) {
        let contentViewController = viewController

        let window = CompletionWindow(contentViewController: contentViewController)
        window.styleMask = [.resizable, .fullSizeContentView]
        window.autorecalculatesKeyViewLoop = true
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isExcludedFromWindowsMenu = true
        window.tabbingMode = .disallowed
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovable = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.setAnchorAttribute(.top, for: .vertical)
        window.setAnchorAttribute(.leading, for: .horizontal)
        window.contentMinSize = CGSize(width: 420, height: 220)

        super.init(window: window)

        contentViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }

    func show() {
        super.showWindow(nil)
    }

    func showWindow(at origin: NSPoint, items: [Any], parent parentWindow: NSWindow) {
        guard let window = window else { return }

        if !isVisible {
            super.showWindow(nil)
            parentWindow.addChildWindow(window, ordered: .above)
        }

        completionViewController.items = items
        window.setFrameTopLeftPoint(origin)

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] notification in
            self?.cleanupOnClose()
        }

        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: .main) { [weak self] notification in
            self?.close()
        }
    }

    private func cleanupOnClose() {
        completionViewController.items.removeAll(keepingCapacity: true)
    }

    override func close() {
        guard isVisible else { return }
        super.close()
    }
}

protocol CompletionWindowDelegate: AnyObject {
    func completionWindowController(_ windowController: CompletionWindowController, complete item: Any, movement: NSTextMovement)
}

extension CompletionWindowController: STCompletionViewControllerDelegate {
    func completionViewController(_ viewController: some STCompletionViewControllerProtocol, complete item: Any, movement: NSTextMovement) {
        delegate?.completionWindowController(self, complete: item, movement: movement)
    }
}
