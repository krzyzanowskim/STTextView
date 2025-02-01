import Foundation

package extension NSRange {
    func clamped(_ limits: NSRange) -> Self? {
        guard let limits = Range(limits),
              let clampedRange = Range(self)?.clamped(to: limits)
        else {
            return nil
        }

        return Self(clampedRange)
    }
}

