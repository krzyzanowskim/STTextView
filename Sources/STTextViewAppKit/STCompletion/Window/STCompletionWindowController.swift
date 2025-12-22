//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

open class STCompletionWindowController: NSWindowController {

    public weak var delegate: STCompletionWindowDelegate?
    private var _willCloseNotificationObserver: NSObjectProtocol?
    private var _didResignKeyNotificationObserver: NSObjectProtocol?

    private var completionViewController: any STCompletionViewControllerProtocol {
        window!.contentViewController as! any STCompletionViewControllerProtocol
    }

    public var isVisible: Bool {
        window?.isVisible ?? false
    }

    public init(_ viewController: some STCompletionViewControllerProtocol) {
        let contentViewController = viewController

        let window = STCompletionWindow(contentViewController: contentViewController)
        window.setContentSize(CGSize(width: 450, height: 22 * 6.5))
        window.contentMinSize = CGSize(width: 300, height: 50)
        window.styleMask = [.resizable, .fullSizeContentView]
        window.autorecalculatesKeyViewLoop = true
        window.isReleasedWhenClosed = true
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

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override open func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }

    public func show() {
        super.showWindow(nil)
    }

    public func showWindow(at origin: CGPoint, items: [any STCompletionItem], parent parentWindow: NSWindow) {
        guard let window else { return }

        if !isVisible {
            parentWindow.addChildWindow(window, ordered: .above)

            _willCloseNotificationObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
                self?.cleanupOnClose()
            }

            _didResignKeyNotificationObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: .main) { [weak self] _ in
                self?.close()
            }
        }

        completionViewController.items = items
        window.setFrameTopLeftPoint(origin)
    }

    private func cleanupOnClose() {
        completionViewController.items.removeAll(keepingCapacity: true)
    }

    override open func close() {
        guard isVisible else { return }
        _willCloseNotificationObserver = nil
        _didResignKeyNotificationObserver = nil
        super.close()
    }
}

public protocol STCompletionWindowDelegate: AnyObject {
    func completionWindowController(_ windowController: STCompletionWindowController, complete item: any STCompletionItem, movement: NSTextMovement)
    func completionWindowControllerCancel(_ windowController: STCompletionWindowController)
}

extension STCompletionWindowController: STCompletionViewControllerDelegate {
    public func completionViewController(_ viewController: some STCompletionViewControllerProtocol, complete item: any STCompletionItem, movement: NSTextMovement) {
        delegate?.completionWindowController(self, complete: item, movement: movement)
    }

    public func completionViewControllerCancel(_ viewController: some STCompletionViewControllerProtocol) {
        delegate?.completionWindowControllerCancel(self)
    }
}
