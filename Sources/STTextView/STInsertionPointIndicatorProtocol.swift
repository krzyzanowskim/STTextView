import AppKit

/// Custom insertion point indicator view. Optional.
public protocol STInsertionPointIndicatorProtocol: NSView {
    var insertionPointColor: NSColor { get set }

    func blinkStart()
    func blinkStop()
}
