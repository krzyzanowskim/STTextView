//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

public protocol STPlugin {
    associatedtype Coordinator = Void
    typealias Context = STPluginContext<Self>
    typealias CoordinatorContext = STPluginCoordinatorContext

    /// Provides an opportunity to setup plugin environment
    func setUp(context: Context)

    /// Creates an object to coordinate with the text view.
    func makeCoordinator(context: CoordinatorContext) -> Self.Coordinator

    /// Provides an opportunity to perform cleanup after plugin is about to remove.
    func tearDown()
}

public extension STPlugin {

    func tearDown() {
        // Nothing
    }
}

public extension STPlugin where Coordinator == Void {

    func makeCoordinator(context: CoordinatorContext) -> Coordinator {
        return ()
    }

}
