import Cocoa

internal final class CompletionWindow: NSWindow {

    override var canBecomeKey: Bool {
        // Disables keyboard events, but gives nice feeling where
        // tableview is not disabled, hence hacked in keyDown
        false
    }

}

