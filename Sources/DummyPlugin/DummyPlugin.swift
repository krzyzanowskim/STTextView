import Foundation
import OSLog
import STTextView

internal let logger = Logger(subsystem: "best.swift.sttextview", category: "DummyPlugin")

public class DummyPlugin: Plugin {

    public init() {
        //
    }

    public func setUp(textView: STTextView) {
        logger.debug("set up dummy plugin")
    }

    public func tearDown() {
        logger.debug("tear down dummy plugin")
    }

}
