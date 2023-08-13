//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

/// Base Plugin class. Subclassed by plugins.
open class STPlugin {
    private var delegateProxy: STTextViewDelegateProxy?

    public init() {
        //
    }

    open func setUp(textView: STTextView) {
        //
    }

    open func tearDown() {
        // unproxy
        delegateProxy?.textView?.delegate = delegateProxy?.sourceDelegate
        delegateProxy = nil
    }

    deinit {
        tearDown()
    }

    public func register(eventHandler handler: STPluginEventHandler?, of textView: STTextView) {
        self.delegateProxy = STTextViewDelegateProxy(textView: textView, handler: handler)
        textView.delegate = delegateProxy
    }

}
