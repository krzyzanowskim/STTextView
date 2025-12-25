//  Created by Claude Code
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation

/// NSSecureCoding-compliant box for STAnnotationRenderAttribute.
///
/// NSAttributedString requires values to be NSObject-compatible for the Objective-C bridge.
/// This wrapper allows storing the Swift struct safely using NSSecureCoding.
///
/// Usage:
/// ```swift
/// let attr = STAnnotationRenderAttribute(style: .wavyUnderline, color: .red)
/// let box = STAnnotationRenderAttributeBox(attribute: attr)
/// textStorage.addAttribute(STAnnotationRenderKey, value: box, range: range)
///
/// // Reading back:
/// if let box = textStorage.attribute(STAnnotationRenderKey, at: index, effectiveRange: nil) as? STAnnotationRenderAttributeBox {
///     let attr = box.attribute
/// }
/// ```
@objc public final class STAnnotationRenderAttributeBox: NSObject, NSSecureCoding {
  public static var supportsSecureCoding: Bool { true }

  public let attribute: STAnnotationRenderAttribute

  public init(attribute: STAnnotationRenderAttribute) {
    self.attribute = attribute
    super.init()
  }

  public required init?(coder: NSCoder) {
    guard let data = coder.decodeObject(of: NSData.self, forKey: "data") as? Data else {
      return nil
    }

    do {
      self.attribute = try JSONDecoder().decode(STAnnotationRenderAttribute.self, from: data)
    } catch {
      assertionFailure("STAnnotationRenderAttributeBox: failed to decode attribute: \(error)")
      return nil
    }

    super.init()
  }

  public func encode(with coder: NSCoder) {
    do {
      let data = try JSONEncoder().encode(attribute)
      coder.encode(data as NSData, forKey: "data")
    } catch {
      assertionFailure("STAnnotationRenderAttributeBox: failed to encode attribute: \(error)")
    }
  }

  // MARK: - Equatable

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? STAnnotationRenderAttributeBox else {
      return false
    }
    return attribute == other.attribute
  }

  public override var hash: Int {
    attribute.hashValue
  }
}
