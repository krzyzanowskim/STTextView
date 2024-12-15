import AppKit

final class STTextFinderBarContainer: NSObject, NSTextFinderBarContainer {

    // Forward NSTextFinderBarContainer to enclosing NSScrollView (for now at least)
    weak var client: STTextView?

    var findBarView: NSView? {
        get {
            client?.scrollView?.findBarView
        }

        set {
            client?.scrollView?.findBarView = newValue

            // Rearrange gutter view position in NSScrollView hierarchy
            Task { @MainActor in
                if let scrollView = client?.scrollView, let gutterView = client?.gutterView {
                    gutterView.removeFromSuperviewWithoutNeedingDisplay()
                    scrollView.addSubview(gutterView, positioned: .below, relativeTo: scrollView.findBarView)
                }
            }
        }
    }

    var isFindBarVisible: Bool {
        get {
            client?.scrollView?.isFindBarVisible ?? false
        }

        set {
            client?.scrollView?.isFindBarVisible = newValue
        }
    }

    func contentView() -> NSView? {
        client?.contentView
    }

    func findBarViewDidChangeHeight() {
        client?.scrollView?.findBarViewDidChangeHeight()
    }
}
