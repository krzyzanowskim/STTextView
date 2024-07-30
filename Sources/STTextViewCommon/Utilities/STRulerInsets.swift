//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

public struct STRulerInsets: Equatable {
    public let leading: CGFloat
    public let trailing: CGFloat
    
    public init(leading: CGFloat = 0, trailing: CGFloat = 0) {
        self.leading = leading
        self.trailing = trailing
    }
    
}
