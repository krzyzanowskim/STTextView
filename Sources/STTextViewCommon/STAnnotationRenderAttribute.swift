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
public struct STAnnotationRenderAttribute: Hashable, Sendable {
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

// MARK: - NSDictionary Serialization

extension STAnnotationRenderAttribute {
  /// Convert to NSDictionary for NSAttributedString storage.
  public func toDictionary() -> NSDictionary {
    var dict: [String: Any] = [
      "style": style.rawValue,
      "red": red,
      "green": green,
      "blue": blue,
      "alpha": alpha,
      "verticalOffset": verticalOffset,
      "thickness": thickness,
    ]
    if let id = id {
      dict["id"] = id
    }
    if let marker = marker {
      dict["marker"] = marker.rawValue
    }
    return dict as NSDictionary
  }

  /// Create from NSDictionary stored in NSAttributedString.
  public init?(dictionary: NSDictionary) {
    guard let dict = dictionary as? [String: Any],
          let styleRaw = dict["style"] as? String,
          let style = STAnnotationStyle(rawValue: styleRaw),
          let red = dict["red"] as? CGFloat,
          let green = dict["green"] as? CGFloat,
          let blue = dict["blue"] as? CGFloat,
          let alpha = dict["alpha"] as? CGFloat,
          let verticalOffset = dict["verticalOffset"] as? CGFloat,
          let thickness = dict["thickness"] as? CGFloat
    else {
      return nil
    }

    self.id = dict["id"] as? String
    self.style = style
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
    self.verticalOffset = verticalOffset
    self.thickness = thickness

    if let markerRaw = dict["marker"] as? String {
      self.marker = STAnnotationMarker(rawValue: markerRaw)
    } else {
      self.marker = nil
    }
  }
}

// MARK: - STAnnotationStyle RawRepresentable

extension STAnnotationStyle: RawRepresentable {
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
public let STAnnotationRenderKey = NSAttributedString.Key("st.annotationRender")
