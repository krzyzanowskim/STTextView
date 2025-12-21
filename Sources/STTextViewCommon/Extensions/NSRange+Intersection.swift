//  Created by Claude Code
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

extension NSRange {
  /// Returns the intersection of this range with another range, or nil if they don't overlap.
  public func intersection(_ other: NSRange) -> NSRange? {
    let start = max(location, other.location)
    let end = min(location + length, other.location + other.length)

    guard end > start else {
      return nil
    }

    return NSRange(location: start, length: end - start)
  }
}
