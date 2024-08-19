//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    @objc public func toggleRuler(_ sender: Any?) {
        isGutterVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    public var isGutterVisible: Bool {
        set {
            if gutterView == nil, newValue == true {
                let gutterView = STGutterView()
                if let font {
                    gutterView.font = adjustGutterFont(font)
                }
                gutterView.frame.size.width = 40
                if let textColor {
                    gutterView.selectedLineTextColor = textColor
                }
                gutterView.highlightSelectedLine = highlightSelectedLine
                gutterView.selectedLineHighlightColor = selectedLineHighlightColor
                if let scrollView = enclosingScrollView {
                    scrollView.addSubview(gutterView)
                }
                self.gutterView = gutterView
            } else if newValue == false {
                gutterView?.removeFromSuperview()
                gutterView = nil
            }
            layoutGutter()
        }
        get {
            gutterView != nil
        }
    }

    internal func layoutGutter() {
        if let gutterView {
            gutterView.frame.origin = frame.origin
            gutterView.frame.size.height = frame.height
        }
        contentView.bounds.origin.x = -(gutterView?.frame.width ?? 0)
        selectionView.bounds.origin.x = -(gutterView?.frame.width ?? 0)
        decorationView.bounds.origin.x = -(gutterView?.frame.width ?? 0)
    }
}
