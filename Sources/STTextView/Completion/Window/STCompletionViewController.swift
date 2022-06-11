import Cocoa
import SwiftUI

public protocol STCompletionViewControllerDelegate: AnyObject {
    func completionViewController(_ viewController: some STCompletionViewControllerProtocol, complete item: Any, movement: NSTextMovement)
}

public protocol STCompletionViewControllerProtocol: NSViewController {
    var items: [Any] { get set }
    var delegate: STCompletionViewControllerDelegate? { get set }
}

open class STCompletionViewController: NSViewController, STCompletionViewControllerProtocol {

    open var items: [Any] = [] {
        didSet {
            tableView.reloadData()

            // preselect first row
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    public weak var delegate: STCompletionViewControllerDelegate?
    private let tableView = NSTableView()
    private var contentScrollView: NSScrollView!

    private var eventMonitor: Any?

    open override func loadView() {
        view = NSView(frame: CGRect(x: 0, y: 0, width: 420, height: 220))
        view.autoresizingMask = [.width, .height]

        do {
            tableView.style = .inset
            tableView.headerView = nil
            tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
            tableView.allowsColumnResizing = false
            tableView.rowHeight = 22
            tableView.backgroundColor = .windowBackgroundColor
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

            let scrollView = NSScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.drawsBackground = false
            scrollView.autoresizingMask = [.width, .height]
            scrollView.hasVerticalScroller = true
            scrollView.documentView = tableView
            view.addSubview(scrollView)
            contentScrollView = scrollView
        }
    }

    @objc func tableViewAction(_ sender: Any?) {
        // select row
    }

    @objc func tableViewDoubleAction(_ sender: Any?) {
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
                        //self.window?.windowController?.insertText(c)
                        //NSSound.beep()
                        break
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

    public override func insertTab(_ sender: Any?) {
        self.insertCompletion(movement: .tab)
    }

    public override func insertLineBreak(_ sender: Any?) {
        self.insertCompletion(movement: .return)
    }

    public override func insertNewline(_ sender: Any?) {
        self.insertCompletion(movement: .return)
    }

    public override func deleteBackward(_ sender: Any?) {
        view.window?.windowController?.close()
    }

    public override func deleteForward(_ sender: Any?) {
        view.window?.windowController?.close()
    }

    public override func cancelOperation(_ sender: Any?) {
        view.window?.windowController?.close()
    }

    private func insertCompletion(movement: NSTextMovement) {
        defer {
            self.view.window?.close()
        }

        guard tableView.selectedRow != -1 else { return }
        let item = items[tableView.selectedRow]
        delegate?.completionViewController(self, complete: item, movement: movement)
    }

}

extension STCompletionViewController: NSTableViewDelegate {

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }

        let item = items[row] as! STCompletion.Item

        switch tableColumn.identifier {
            case .labelColumn:
                let cellView = tableView.reuseOrCreateTableView(withIdentifier: .labelColumn) as CompletionLabelCellView
                cellView.setup(with: item)
                return cellView
            default:
                assertionFailure("Unknown column")
                return nil
        }
    }

}

extension STCompletionViewController: NSTableViewDataSource {
    open func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }
}

private class TableCellView: NSTableCellView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.drawsBackground = false
        textField.maximumNumberOfLines = 1
        textField.lineBreakMode = .byTruncatingTail
        textField.bezelStyle = .roundedBezel
        textField.isBordered = false
        textField.autoresizingMask = [.width, .height]

        addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        self.textField = textField
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class CompletionLabelCellView: TableCellView {

    func setup(with item: STCompletion.Item) {
        guard let textField = textField else { return }
        textField.font = .userFixedPitchFont(ofSize: NSFont.systemFontSize)
        textField.textColor = .labelColor
        textField.stringValue = item.label
        textField.allowsExpansionToolTips = true
    }

}

private extension NSTableView {
    func reuseOrCreateTableView<V: NSView>(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> V {
        guard let view = makeView(withIdentifier: identifier, owner: self) else {
            let view = V()
            view.identifier = identifier
            return view
        }
        return view as! V
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let labelColumn = NSUserInterfaceItemIdentifier("LabelColumn")
}
