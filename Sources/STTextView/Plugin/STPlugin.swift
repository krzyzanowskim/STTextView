//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

public protocol STPlugin {
    associatedtype Coordinator = Void
    typealias Context = STPluginContext<Self>

    /// Provides an opportunity to setup plugin environment
    func setUp(context: Context)

    /// Creates an object to coordinate with the text view.
    func makeCoordinator() -> Self.Coordinator

    /// Provides an opportunity to perform cleanup after plugin is about to remove.
    func tearDown()
}

public extension STPlugin {

    func tearDown() {
        // Nothing
    }
}

public extension STPlugin where Coordinator == Void {
    func makeCoordinator() -> Coordinator {
        return ()
    }
}

/// Base Plugin class. Subclassed by plugins.
//open class STPlugin {
//
//    public required init() {
//
//    }
//
//    public class Context {
//        /// Text view reference
//        private var delegateProxy: STTextViewDelegateProxy?
//
//        public weak var textView: STTextView!
//
//        init(textView: STTextView) {
//            self.textView = textView
//        }
//    }
//
//    internal func setUp(textView: STTextView) {
//        let context = Context(textView: textView)
//        self.setUp(context: context)
//    }
//
//    open func setUp(context: Context) {
//
//    }
//
//    open func tearDown() {
//        // unproxy
////        delegateProxy?.textView?.delegate = delegateProxy?.sourceDelegate
////        delegateProxy = nil
//    }
//
//    deinit {
//        tearDown()
//    }
//
////    public func register(eventHandler handler: STPluginEventHandler?, of textView: STTextView) {
////        self.delegateProxy = STTextViewDelegateProxy(textView: textView, handler: handler)
////        textView.delegate = delegateProxy
////    }
//
//}
