//  Created by Claude Code
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias STColor = NSColor
#elseif canImport(UIKit)
import UIKit
public typealias STColor = UIColor
#endif

/// Style of annotation decoration.
public enum STAnnotationStyle: Sendable {
  /// Solid line underline.
  case solidUnderline
  /// Dashed line underline (— — —).
  case dashedUnderline
  /// Dotted line underline (• • •).
  case dottedUnderline
  /// Wavy/squiggly line underline.
  case wavyUnderline
  /// Solid background highlight.
  case background
}

/// A decoration that marks a range of text with underlines or backgrounds.
///
/// Annotation decorations are rendered efficiently by the text view,
/// only drawing decorations for visible text fragments.
public struct STAnnotationDecoration: Sendable {
  /// The character range to decorate (NSRange with location and length).
  public let range: NSRange

  /// The style of decoration to draw.
  public let style: STAnnotationStyle

  /// The color of the decoration.
  public let color: STColor

  /// Vertical offset from the text baseline for underlines (positive = down).
  /// Ignored for background style.
  public let verticalOffset: CGFloat

  /// Line thickness for underlines, or corner radius for backgrounds.
  public let thickness: CGFloat

  /// Shape of the marker at the start of underlines.
  /// Ignored for background style.
  public let marker: STAnnotationMarker

  /// Creates an annotation decoration.
  ///
  /// - Parameters:
  ///   - range: The character range to decorate
  ///   - style: The decoration style (underline variants or background)
  ///   - color: The decoration color
  ///   - verticalOffset: Vertical offset from baseline for underlines (default: 2)
  ///   - thickness: Line thickness for underlines, corner radius for backgrounds (default: 1.5)
  ///   - marker: Shape of the start marker for underlines (default: .circle)
  public init(
    range: NSRange,
    style: STAnnotationStyle,
    color: STColor,
    verticalOffset: CGFloat = 2,
    thickness: CGFloat = 1.5,
    marker: STAnnotationMarker = .circle
  ) {
    self.range = range
    self.style = style
    self.color = color
    self.verticalOffset = verticalOffset
    self.thickness = thickness
    self.marker = marker
  }
}
