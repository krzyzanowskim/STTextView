//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

open class STCompletionWindowController: NSWindowController {

    public weak var delegate: STCompletionWindowDelegate?

    private var completionViewController: any STCompletionViewControllerProtocol {
        window!.contentViewController as! any STCompletionViewControllerProtocol
    }

    public var isVisible: Bool {
        window?.isVisible ?? false
    }

    public init<T: STCompletionViewControllerProtocol>(_ viewController: T) {
        let contentViewController = viewController

        let window = STCompletionWindow(contentViewController: contentViewController)
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

        super.init(window: window)

        contentViewController.delegate = self
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    open override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }

    public func show() {
        super.showWindow(nil)
    }

    public func showWindow(at origin: CGPoint, items: [any STCompletionItem], parent parentWindow: NSWindow) {
        guard let window = window else { return }

        if !isVisible {
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

    open override func close() {
        guard isVisible else { return }
        super.close()
    }
}

public protocol STCompletionWindowDelegate: AnyObject {
    func completionWindowController(_ windowController: STCompletionWindowController, complete item: any STCompletionItem, movement: NSTextMovement)
}

extension STCompletionWindowController: STCompletionViewControllerDelegate {
    public func completionViewController<T: STCompletionViewControllerProtocol>(_ viewController: T, complete item: any STCompletionItem, movement: NSTextMovement) {
        delegate?.completionWindowController(self, complete: item, movement: movement)
    }
}
