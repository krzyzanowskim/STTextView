//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import CoreGraphics

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

package extension CGRect {

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    typealias EdgeInsets = NSEdgeInsets
    #else
    typealias EdgeInsets = UIEdgeInsets
    #endif

    enum Inset {
        case left(CGFloat)
        case right(CGFloat)
        case top(CGFloat)
        case bottom(CGFloat)
    }

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func inset(by edgeInsets: EdgeInsets) -> CGRect {
        var result = self
        result.origin.x += edgeInsets.left
        result.origin.y += edgeInsets.top
        result.size.width -= edgeInsets.left + edgeInsets.right
        result.size.height -= edgeInsets.top + edgeInsets.bottom
        return result
    }
#endif

    func inset(_ insets: Inset...) -> CGRect {
        var result = self
        for inset in insets {
            switch inset {
                case .left(let value):
                    result = self.inset(by: EdgeInsets(top: 0, left: value, bottom: 0, right: 0))
                case .right(let value):
                    result = self.inset(by: EdgeInsets(top: 0, left: 0, bottom: 0, right: value))
                case .top(let value):
                    result = self.inset(by: EdgeInsets(top: value, left: 0, bottom: 0, right: 0))
                case .bottom(let value):
                    result = self.inset(by: EdgeInsets(top: 0, left: 0, bottom: value, right: 0))
            }
        }
        return result
    }

    func inset(dx: CGFloat = 0, dy: CGFloat = 0) -> CGRect {
        insetBy(dx: dx, dy: dy)
    }

    func scale(_ scale: CGSize) -> CGRect {
        applying(.init(scaleX: scale.width, y: scale.height))
    }

    func margin(_ margin: CGSize) -> CGRect {
        insetBy(dx: -margin.width / 2, dy: -margin.height / 2)
    }

    func moved(dx: CGFloat = 0, dy: CGFloat = 0) -> CGRect {
        applying(.init(translationX: dx, y: dy))
    }

    func moved(by point: CGPoint) -> CGRect {
        applying(.init(translationX: point.x, y: point.y))
    }

    func margin(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> CGRect {
        inset(by: .init(top: -top, left: -left, bottom: -bottom, right: -right))
    }
}

package extension CGPoint {
    func moved(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        applying(.init(translationX: dx, y: dy))
    }

    func moved(by point: CGPoint) -> CGPoint {
        applying(.init(translationX: point.x, y: point.y))
    }
}

package extension CGRect {
    func isAlmostEqual(to other: CGRect) -> Bool {
        origin.isAlmostEqual(to: other.origin) && size.isAlmostEqual(to: other.size)
    }
}

package extension CGPoint {
    func isAlmostEqual(to other: CGPoint) -> Bool {
        x.isAlmostEqual(to: other.x) && y.isAlmostEqual(to: other.y)
    }
}

package extension CGSize {
    func isAlmostEqual(to other: CGSize) -> Bool {
        width.isAlmostEqual(to: other.width) && height.isAlmostEqual(to: other.height)
    }
}
