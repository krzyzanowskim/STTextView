import Foundation

extension NSEdgeInsets {
    var horizontalInsets: CGFloat {
        left + right
    }

    var verticalInsets: CGFloat {
        top + bottom
    }
}
