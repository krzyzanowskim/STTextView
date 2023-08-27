import AppKit

extension NSTextLineFragment {

    /// Returns a text range inside privided textLayoutFragment.
    ///
    /// Returned range is relative to the document range origin.
    /// - Parameter textLayoutFragment: Text layout fragment
    /// - Returns: Text range or nil
    public func textRange(in textLayoutFragment: NSTextLayoutFragment) -> NSTextRange? {

        guard let textContentManager = textLayoutFragment.textLayoutManager?.textContentManager else {
            assertionFailure()
            return nil
        }

        return NSTextRange(
            location: textContentManager.location(textLayoutFragment.rangeInElement.location, offsetBy: characterRange.location)!,
            end: textContentManager.location(textLayoutFragment.rangeInElement.location, offsetBy: characterRange.location + characterRange.length)
        )
    }
}
