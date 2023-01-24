//  Created by Elias Wahl on 14.01.23.
import Foundation

public struct STRulerInsets: Equatable {
    public let leading: CGFloat
    public let trailing: CGFloat
    
    public init(leading: CGFloat, trailing: CGFloat) {
        self.leading = leading
        self.trailing = trailing
    }
    
}
