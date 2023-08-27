//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import SwiftUI

open class STCompletionViewController: NSViewController, STCompletionViewControllerProtocol {

    public weak var delegate: STCompletionViewControllerDelegate?

    open var items: [any STCompletionItem] = [] {
        didSet {
            tableView.reloadData()
            view.needsUpdateConstraints = true
        }
    }

    public let tableView = NSTableView()

    private var eventMonitor: Any?

    open override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 5
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        NSLayoutConstraint.activate(
            [
                view.widthAnchor.constraint(greaterThanOrEqualToConstant: 320)
            ]
        )

        tableView.style = .plain
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.allowsColumnResizing = false
        tableView.rowHeight = 22
        tableView.usesAutomaticRowHeights = false
        tableView.rowSizeStyle = .custom
        tableView.intercellSpacing = CGSize(width: 4, height: 2)
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        tableView.allowsEmptySelection = false
        tableView.action = #selector(tableViewAction(_:))
        tableView.doubleAction = #selector(tableViewDoubleAction(_:))
        tableView.target = self

        do {
            let nameColumn = NSTableColumn(identifier: .labelColumn)
            nameColumn.resizingMask = .autoresizingMask
            tableView.addTableColumn(nameColumn)
        }

        tableView.dataSource = self
        tableView.delegate = self

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView

        view.addSubview(scrollView)
        NSLayoutConstraint.activate(
            [
                scrollView.topAnchor.constraint(equalTo: view.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
    }

    @objc open func tableViewAction(_ sender: Any?) {
        // select row
    }

    @objc open func tableViewDoubleAction(_ sender: Any?) {
        insertCompletion(movement: .other)
    }

    open override func viewDidAppear() {
        super.viewDidAppear()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            guard let self = self else { return nil }

            if let characters = event.characters {
                for c in characters {
                    switch c {
                    case "\u{001B}", // esc
                         "\u{0009}", // NSTabCharacter
                         "\u{0008}", // NSBackspaceCharacter
                         "\u{007F}", // NSDeleteCharacter
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
                        self.cancelOperation(self)
                    }
                }
            }
            return event
        }
    }

    open override func viewDidDisappear() {
        super.viewDidDisappear()

        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }

    private var heightConstraint: NSLayoutConstraint!

    open override func updateViewConstraints() {
        if heightConstraint == nil {
            heightConstraint = view.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
            heightConstraint.isActive = true
        }

        let maxVisibleItemsCount = min(8.5, CGFloat(items.count))
        heightConstraint.constant = max(
            tableView.rowHeight,
            (maxVisibleItemsCount * tableView.rowHeight) + (tableView.intercellSpacing.height * maxVisibleItemsCount) + (tableView.enclosingScrollView!.contentInsets.top + tableView.enclosingScrollView!.contentInsets.bottom)
        )

        super.updateViewConstraints()
    }

    open override func insertTab(_ sender: Any?) {
        self.insertCompletion(movement: .tab)
    }

    open override func insertLineBreak(_ sender: Any?) {
        self.insertCompletion(movement: .return)
    }

    open override func insertNewline(_ sender: Any?) {
        self.insertCompletion(movement: .return)
    }

    open override func deleteBackward(_ sender: Any?) {
        view.window?.windowController?.close()
    }

    open override func deleteForward(_ sender: Any?) {
        view.window?.windowController?.close()
    }

    open override func cancelOperation(_ sender: Any?) {
        view.window?.windowController?.close()
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
        STTableRowView()
    }

}

extension STCompletionViewController: NSTableViewDataSource {
    open func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }
}

private class STTableRowView: NSTableRowView {

    override func drawSelection(in dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        let path = NSBezierPath(roundedRect: dirtyRect, xRadius: 4, yRadius: 4)
        context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.7).cgColor)
        path.fill()
        context.restoreGState()
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let labelColumn = NSUserInterfaceItemIdentifier("LabelColumn")
}
