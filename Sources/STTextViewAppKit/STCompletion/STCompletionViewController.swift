//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import SwiftUI

open class STCompletionViewController: NSViewController, STCompletionViewControllerProtocol {

    public weak var delegate: STCompletionViewControllerDelegate?
    public private(set) var tableView: NSTableView!
    private var _scrollView: NSScrollView!

    open var items: [any STCompletionItem] = [] {
        didSet {
            tableView.reloadData()
            view.needsUpdateConstraints = true
        }
    }

    private var _eventMonitor: Any?

    override open func loadView() {
        view = NSView(frame: .zero)
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.cornerCurve = .continuous

        let backgroundEffect = NSVisualEffectView(frame: view.frame)
        backgroundEffect.autoresizingMask = [.width, .height]
        backgroundEffect.blendingMode = .withinWindow
        backgroundEffect.material = .windowBackground
        backgroundEffect.state = .followsWindowActiveState
        backgroundEffect.wantsLayer = true
        view.addSubview(backgroundEffect)

        tableView = NSTableView(frame: view.frame)
        tableView.autoresizingMask = [.width, .height]

        let scrollView = NSScrollView(frame: view.frame)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        self._scrollView = scrollView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        _scrollView.automaticallyAdjustsContentInsets = false
        _scrollView.contentInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        _scrollView.backgroundColor = NSColor.gridColor
        _scrollView.borderType = .noBorder
        _scrollView.hasVerticalScroller = true
        _scrollView.verticalScroller = NoKnobScroller()

        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.allowsColumnResizing = false
        tableView.usesAutomaticRowHeights = false
        tableView.backgroundColor = .clear
        tableView.headerView = nil
        tableView.rowHeight = 22
        tableView.rowSizeStyle = .custom
        tableView.intercellSpacing = CGSize(width: 4, height: 2)
        tableView.selectionHighlightStyle = .regular
        tableView.allowsEmptySelection = false
        tableView.action = #selector(tableViewAction(_:))
        tableView.doubleAction = #selector(tableViewDoubleAction(_:))
        tableView.target = self
        tableView.dataSource = self
        tableView.delegate = self

        do {
            let labelColumn = NSTableColumn(identifier: .labelColumn)
            labelColumn.resizingMask = .autoresizingMask
            tableView.addTableColumn(labelColumn)
        }

    }

    @objc open func tableViewAction(_ sender: Any?) {
        // select row
    }

    @objc open func tableViewDoubleAction(_ sender: Any?) {
        insertCompletion(movement: .other)
    }

    override open func viewDidAppear() {
        super.viewDidAppear()

        _eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self else { return nil }

            if let characters = event.characters {
                for c in characters {
                    switch c {
                    case "\u{001B}", // esc
                         "\u{0009}", // NSTabCharacter
                         "\u{000A}", // NSNewlineCharacter
                         "\u{000D}", // NSCarriageReturnCharacter
                         "\u{0003}": // NSEnterCharacter
                        self.interpretKeyEvents([event])
                        return nil
                    case "\u{F701}", // NSDownArrowFunctionKey
                         "\u{F700}": // NSUpArrowFunctionKey
                        self.tableView.keyDown(with: event)
                        return nil
                    default:
                        // Ignore other event
                        break
                    }
                }
            }
            return event
        }
    }

    override open func viewDidDisappear() {
        super.viewDidDisappear()

        if let eventMonitor = _eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        _eventMonitor = nil
    }

    override open func insertTab(_ sender: Any?) {
        self.insertCompletion(movement: .tab)
    }

    override open func insertLineBreak(_ sender: Any?) {
        self.insertCompletion(movement: .return)
    }

    override open func insertNewline(_ sender: Any?) {
        self.insertCompletion(movement: .return)
    }

    override open func cancelOperation(_ sender: Any?) {
        delegate?.completionViewControllerCancel(self)
    }

    private func insertCompletion(movement: NSTextMovement) {
        defer {
            self.cancelOperation(self)
        }

        guard tableView.selectedRow != -1 else { return }
        let item = items[tableView.selectedRow]
        delegate?.completionViewController(self, complete: item, movement: movement)
    }

}

extension STCompletionViewController: NSTableViewDelegate {

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        items[row].view
    }

    open func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        STTableRowView(parentCornerRadius: view.layer!.cornerRadius, inset: tableView.enclosingScrollView?.contentInsets.top ?? 0)
    }

}

extension STCompletionViewController: NSTableViewDataSource {
    open func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }
}

private class STTableRowView: NSTableRowView {

    private let _parentCornerRadius: CGFloat
    private let _inset: CGFloat

    init(parentCornerRadius: CGFloat, inset: CGFloat) {
        self._parentCornerRadius = parentCornerRadius * 2
        self._inset = inset
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawSelection(in dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if isSelected {
            context.saveGState()
            let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            let radius = (_parentCornerRadius - _inset) / 2
            let path = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
            context.setFillColor(NSColor.highlightColor.withAlphaComponent(isDark ? 0.2 : 1).cgColor)
            path.fill()
            context.restoreGState()
        }
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let labelColumn = NSUserInterfaceItemIdentifier("LabelColumn")
}

private final class NoKnobScroller: NSScroller {
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {}

    override class var isCompatibleWithOverlayScrollers: Bool {
        true
    }
}
