//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

public protocol STPluginProtocol {
    func setUp(textView: STTextView)
    func tearDown()
}
