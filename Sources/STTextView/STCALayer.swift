//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import QuartzCore

open class STCALayer: CALayer {

    public var enableAnimations: Bool = false

    // Suppress default animation of opacity when adding comment bubbles.
    override public class func defaultAction(forKey event: String) -> CAAction? {
        return NSNull()
    }

    /// A dictionary containing layer actions.
    /// Disable animations
    override public var actions: [String : CAAction]? {
        set {
            if !enableAnimations {
                return
            }

            super.actions = newValue
        }

        get {
            super.actions
        }
    }

    public init(frame frameRect: CGRect) {
        super.init()
        needsDisplayOnBoundsChange = true
        contentsScale = 2
        frame = frameRect
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        needsDisplayOnBoundsChange = true
        contentsScale = 2
    }

    public override init(layer: Any) {
        super.init(layer: layer)
        contentsScale = 2
        needsDisplayOnBoundsChange = true
    }
}
