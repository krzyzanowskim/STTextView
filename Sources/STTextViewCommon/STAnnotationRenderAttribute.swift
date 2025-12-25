//  Created by Claude Code
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - STAnnotationMarker

/// Marker shape displayed at the start of an annotation underline.
public enum STAnnotationMarker: String, Hashable, Sendable, Codable {
  case circle
  case square
  case diamond
  case triangle
}

// MARK: - STAnnotationRenderAttribute

/// Attribute containing all info needed to render an annotation.
///
/// This attribute is stored in NSAttributedString and read directly by
/// STTextLayoutFragmentView to render annotations without a separate array.
///
/// The range is determined by where this attribute is applied in the text,
/// eliminating the need to store it in the value itself.
///
/// Use `STAnnotationRenderAttributeBox` to wrap this for NSAttributedString storage:
/// ```swift
/// let attr = STAnnotationRenderAttribute(style: .wavyUnderline, color: .red)
/// let box = STAnnotationRenderAttributeBox(attribute: attr)
/// textStorage.addAttribute(STAnnotationRenderKey, value: box, range: range)
/// ```
public struct STAnnotationRenderAttribute: Hashable, Sendable, Codable {
  /// Optional app-specific ID for tracking (STTextView ignores this).
  public let id: String?

  /// The decoration style (underline type or background).
  public let style: STAnnotationStyle

  /// The decoration color (stored as RGBA for Sendable/Codable support).
  public let red: CGFloat
  public let green: CGFloat
  public let blue: CGFloat
  public let alpha: CGFloat

  /// Vertical offset from baseline for underlines (positive = down).
  public let verticalOffset: CGFloat

  /// Line thickness for underlines, or corner radius for backgrounds.
  public let thickness: CGFloat

  /// Optional marker shape at the start of the underline.
  /// TODO: Marker rendering not yet implemented in STTextLayoutFragmentView
  public let marker: STAnnotationMarker?

  public init(
    id: String? = nil,
    style: STAnnotationStyle,
    color: STColor,
    verticalOffset: CGFloat = 2,
    thickness: CGFloat = 2,
    marker: STAnnotationMarker? = nil
  ) {
    self.id = id
    self.style = style
    self.verticalOffset = verticalOffset
    self.thickness = thickness
    self.marker = marker

    // Extract color components
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    let srgbColor = color.usingColorSpace(.sRGB) ?? color
    self.red = srgbColor.redComponent
    self.green = srgbColor.greenComponent
    self.blue = srgbColor.blueComponent
    self.alpha = srgbColor.alphaComponent
    #elseif canImport(UIKit)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    self.red = r
    self.green = g
    self.blue = b
    self.alpha = a
    #endif
  }

  /// Reconstruct the platform color from stored components.
  public var color: STColor {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    #elseif canImport(UIKit)
    UIColor(red: red, green: green, blue: blue, alpha: alpha)
    #endif
  }
}

// MARK: - STAnnotationStyle Codable

extension STAnnotationStyle: Codable, RawRepresentable {
  public init?(rawValue: String) {
    switch rawValue {
    case "solidUnderline": self = .solidUnderline
    case "dashedUnderline": self = .dashedUnderline
    case "dottedUnderline": self = .dottedUnderline
    case "wavyUnderline": self = .wavyUnderline
    case "background": self = .background
    default: return nil
    }
  }

  public var rawValue: String {
    switch self {
    case .solidUnderline: return "solidUnderline"
    case .dashedUnderline: return "dashedUnderline"
    case .dottedUnderline: return "dottedUnderline"
    case .wavyUnderline: return "wavyUnderline"
    case .background: return "background"
    }
  }
}

// MARK: - NSAttributedString Key

/// NSAttributedString key for annotation render attributes.
///
/// Store the boxed attribute in NSAttributedString:
/// ```swift
/// let attr = STAnnotationRenderAttribute(style: .wavyUnderline, color: .red)
/// let box = STAnnotationRenderAttributeBox(attribute: attr)
/// textStorage.addAttribute(STAnnotationRenderKey, value: box, range: range)
/// ```
public let STAnnotationRenderKey = NSAttributedString.Key("st.annotationRender")
