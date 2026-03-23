//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var secondaryWindowControllers: [NSWindowController] = []

    func applicationDidFinishLaunching(_: Notification) {
        openSecondaryWindow()
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        return true
    }

}

private extension AppDelegate {
    func openSecondaryWindow() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let windowController = storyboard.instantiateController(withIdentifier: "SecondaryWindowController") as? NSWindowController,
              windowController.contentViewController is SecondaryTextEditViewController,
              let window = windowController.window
        else {
            assertionFailure("Failed to create secondary window controller")
            return
        }

        secondaryWindowControllers.append(windowController)

        if let mainWindow = NSApp.windows.first {
            var frame = window.frame
            frame.origin.x = mainWindow.frame.maxX + 24
            frame.origin.y = mainWindow.frame.minY - 24
            window.setFrame(frame, display: false)
        }

        window.title = "TextEdit Empty"
        window.makeKeyAndOrderFront(nil)
    }
}
