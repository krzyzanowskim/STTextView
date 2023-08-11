//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

open class STPlugin: STPluginProtocol {
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

    public func register(eventHandler handler: STPluginEventHandler?, of textView: STTextView) {
        self.delegateProxy = STTextViewDelegateProxy(textView: textView, handler: handler)
        textView.delegate = delegateProxy
    }

}
