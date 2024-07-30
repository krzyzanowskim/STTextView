//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import CoreGraphics
import Foundation

extension CGRect {

    package var pixelAligned: CGRect {
        // https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/APIs/APIs.html#//apple_ref/doc/uid/TP40012302-CH5-SW9
        // NSIntegralRectWithOptions(self, [.alignMinXOutward, .alignMinYOutward, .alignWidthOutward, .alignMaxYOutward])
        #if os(macOS) && !targetEnvironment(macCatalyst)
            NSIntegralRectWithOptions(self, AlignmentOptions.alignAllEdgesNearest)
        #elseif os(iOS) || targetEnvironment(macCatalyst)
            NSIntegralRectWithOptions(self, AlignmentOptions.alignAllEdgesNearest)
        #endif
    }

}

#if os(iOS) || targetEnvironment(macCatalyst)

// https://github.com/apple/swift-corelibs-foundation/blob/ca3669eb9ac282c649e71824d9357dbe140c8251/Sources/Foundation/NSGeometry.swift#L812
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

fileprivate func roundedTowardPlusInfinity(_ value: Double) -> Double {
    return floor(value + 0.5)
}

fileprivate func roundedTowardMinusInfinity(_ value: Double) -> Double {
    return ceil(value - 0.5)
}

package struct AlignmentOptions : OptionSet, Sendable {
    public var rawValue : UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }

    public static let alignMinXInward = AlignmentOptions(rawValue: 1 << 0)
    public static let alignMinYInward = AlignmentOptions(rawValue: 1 << 1)
    public static let alignMaxXInward = AlignmentOptions(rawValue: 1 << 2)
    public static let alignMaxYInward = AlignmentOptions(rawValue: 1 << 3)
    public static let alignWidthInward = AlignmentOptions(rawValue: 1 << 4)
    public static let alignHeightInward = AlignmentOptions(rawValue: 1 << 5)

    public static let alignMinXOutward = AlignmentOptions(rawValue: 1 << 8)
    public static let alignMinYOutward = AlignmentOptions(rawValue: 1 << 9)
    public static let alignMaxXOutward = AlignmentOptions(rawValue: 1 << 10)
    public static let alignMaxYOutward = AlignmentOptions(rawValue: 1 << 11)
    public static let alignWidthOutward = AlignmentOptions(rawValue: 1 << 12)
    public static let alignHeightOutward = AlignmentOptions(rawValue: 1 << 13)

    public static let alignMinXNearest = AlignmentOptions(rawValue: 1 << 16)
    public static let alignMinYNearest = AlignmentOptions(rawValue: 1 << 17)
    public static let alignMaxXNearest = AlignmentOptions(rawValue: 1 << 18)
    public static let alignMaxYNearest = AlignmentOptions(rawValue: 1 << 19)
    public static let alignWidthNearest = AlignmentOptions(rawValue: 1 << 20)
    public static let alignHeightNearest = AlignmentOptions(rawValue: 1 << 21)

    // pass this if the rect is in a flipped coordinate system. This allows 0.5 to be treated in a visually consistent way.
    public static let alignRectFlipped = AlignmentOptions(rawValue: 1 << 63)

    // convenience combinations
    public static let alignAllEdgesInward: AlignmentOptions = [.alignMinXInward, .alignMaxXInward, .alignMinYInward, .alignMaxYInward]
    public static let alignAllEdgesOutward: AlignmentOptions = [.alignMinXOutward, .alignMaxXOutward, .alignMinYOutward, .alignMaxYOutward]
    public static let alignAllEdgesNearest: AlignmentOptions = [.alignMinXNearest, .alignMaxXNearest, .alignMinYNearest, .alignMaxYNearest]
}

fileprivate extension AlignmentOptions {
    var isAlignInward: Bool {
        return (rawValue & 0xFF) != 0
    }

    var isAlignNearest: Bool {
        return (rawValue & 0xFF0000) != 0
    }

    var minXOptions: AlignmentOptions {
        return intersection([.alignMinXInward, .alignMinXNearest, .alignMinXOutward])
    }

    var maxXOptions: AlignmentOptions {
        return intersection([.alignMaxXInward, .alignMaxXNearest, .alignMaxXOutward])
    }

    var widthOptions: AlignmentOptions {
        return intersection([.alignWidthInward, .alignWidthNearest, .alignWidthOutward])
    }

    var minYOptions: AlignmentOptions {
        return intersection([.alignMinYInward, .alignMinYNearest, .alignMinYOutward])
    }

    var maxYOptions: AlignmentOptions {
        return intersection([.alignMaxYInward, .alignMaxYNearest, .alignMaxYOutward])
    }

    var heightOptions: AlignmentOptions {
        return intersection([.alignHeightInward, .alignHeightNearest, .alignHeightOutward])
    }
}

extension AlignmentOptions {
    func assertValid() {
        let inAttributes = rawValue & 0xFF
        let outAttributes = (rawValue & 0xFF00) >> 8
        let nearestAttributes = (rawValue & 0xFF0000) >> 16

        let horizontal: AlignmentOptions = [.alignMinXInward, .alignMinXOutward, .alignMinXNearest, .alignMaxXInward, .alignMaxXOutward, .alignMaxXNearest, .alignWidthInward, .alignWidthOutward, .alignWidthNearest]
        let vertical: AlignmentOptions = [.alignMinYInward, .alignMinYOutward, .alignMinYNearest, .alignMaxYInward, .alignMaxYOutward, .alignMaxYNearest, .alignHeightInward, .alignHeightOutward, .alignHeightNearest]

        if ((inAttributes & outAttributes) | (inAttributes & nearestAttributes) | (outAttributes & nearestAttributes)) != 0 {
            preconditionFailure("The options parameter is invalid. Only one of {in, out, nearest} may be set for a given rect attribute.")
        }

        if intersection(horizontal).rawValue.nonzeroBitCount != 2 {
            preconditionFailure("The options parameter is invalid. There should be specifiers for exactly two out of {minX, maxX, width}.")
        }

        if intersection(vertical).rawValue.nonzeroBitCount != 2 {
            preconditionFailure("The options parameter is invalid. There should be specifiers for exactly two out of {minY, maxY, height}.")
        }
    }
}

fileprivate func integralizeRectAttribute(_ num: Double, options: AlignmentOptions, inward: (Double) -> Double, outward: (Double) -> Double, nearest: (Double) -> Double) -> Double {
    let tolerance: Double = (1.0 / Double(1 << 8))
    if options.isAlignNearest {
        let numTimesTwo = num * 2
        let roundedNumTimesTwo = roundedTowardPlusInfinity(numTimesTwo)
        if fabs(numTimesTwo - roundedNumTimesTwo) < 2 * tolerance {
            return nearest(roundedNumTimesTwo / 2)
        } else {
            return nearest(num)
        }
    } else {
        let roundedNum = roundedTowardPlusInfinity(num)
        if fabs(num - roundedNum) < tolerance {
            return roundedNum
        } else {
            if options.isAlignInward {
                return inward(num)
            } else {
                return outward(num)
            }
        }
    }
}

private func NSIntegralRectWithOptions(_ aRect: CGRect, _ opts: AlignmentOptions) -> CGRect {
    opts.assertValid()

    var integralRect: CGRect = .zero
    let horizontalEdgeNearest = roundedTowardPlusInfinity
    let verticalEdgeNearest = opts.contains(.alignRectFlipped) ? roundedTowardMinusInfinity : roundedTowardPlusInfinity

    // two out of these three sets of options will have a single bit set:
    let minXOptions = opts.minXOptions
    let maxXOptions = opts.maxXOptions
    let widthOptions = opts.widthOptions

    if minXOptions.isEmpty {
        // we have a maxX and a width
        integralRect.size.width = CGFloat(integralizeRectAttribute(Double(aRect.width),
                                                                   options: widthOptions,
                                                                   inward: floor,
                                                                   outward: ceil,
                                                                   nearest: roundedTowardPlusInfinity))
        integralRect.origin.x   = CGFloat(integralizeRectAttribute(Double(aRect.maxX),
                                                                   options: maxXOptions,
                                                                   inward: floor,
                                                                   outward: ceil,
                                                                   nearest: horizontalEdgeNearest)) - integralRect.width
    } else if maxXOptions.isEmpty {
        // we have a minX and a width
        integralRect.origin.x   = CGFloat(integralizeRectAttribute(Double(aRect.minX),
                                                                   options: minXOptions,
                                                                   inward: ceil,
                                                                   outward: floor,
                                                                   nearest: horizontalEdgeNearest))
        integralRect.size.width = CGFloat(integralizeRectAttribute(Double(aRect.width),
                                                                   options: widthOptions,
                                                                   inward: floor,
                                                                   outward: ceil,
                                                                   nearest: roundedTowardPlusInfinity))
    } else {
        // we have a minX and a width
        integralRect.origin.x   = CGFloat(integralizeRectAttribute(Double(aRect.minX),
                                                                   options: minXOptions,
                                                                   inward: ceil,
                                                                   outward: floor,
                                                                   nearest: horizontalEdgeNearest))
        integralRect.size.width = CGFloat(integralizeRectAttribute(Double(aRect.maxX),
                                                                   options: maxXOptions,
                                                                   inward: floor,
                                                                   outward: ceil,
                                                                   nearest: horizontalEdgeNearest)) - integralRect.minX
    }

    // no negarects
    integralRect.size.width = max(integralRect.size.width, 0)

    // two out of these three sets of options will have a single bit set:
    let minYOptions = opts.minYOptions
    let maxYOptions = opts.maxYOptions
    let heightOptions = opts.heightOptions

    if minYOptions.isEmpty {
        // we have a maxY and a height
        integralRect.size.height = CGFloat(integralizeRectAttribute(Double(aRect.height),
                                                                    options: heightOptions,
                                                                    inward: floor,
                                                                    outward: ceil,
                                                                    nearest: roundedTowardPlusInfinity))
        integralRect.origin.y    = CGFloat(integralizeRectAttribute(Double(aRect.maxY),
                                                                    options: maxYOptions,
                                                                    inward: floor,
                                                                    outward: ceil,
                                                                    nearest: verticalEdgeNearest)) - integralRect.height
    } else if maxYOptions.isEmpty {
        // we have a minY and a height
        integralRect.origin.y    = CGFloat(integralizeRectAttribute(Double(aRect.minY),
                                                                    options: minYOptions,
                                                                    inward: ceil,
                                                                    outward: floor,
                                                                    nearest: verticalEdgeNearest))
        integralRect.size.height = CGFloat(integralizeRectAttribute(Double(aRect.height),
                                                                    options: heightOptions,
                                                                    inward: floor,
                                                                    outward: ceil,
                                                                    nearest: roundedTowardPlusInfinity))
    } else {
        // we have a minY and a maxY
        integralRect.origin.y    = CGFloat(integralizeRectAttribute(Double(aRect.minY),
                                                                    options: minYOptions,
                                                                    inward: ceil,
                                                                    outward: floor,
                                                                    nearest: verticalEdgeNearest))
        integralRect.size.height = CGFloat(integralizeRectAttribute(Double(aRect.maxY),
                                                                    options: maxYOptions,
                                                                    inward: floor,
                                                                    outward: ceil,
                                                                    nearest: verticalEdgeNearest)) - integralRect.minY
    }

    // no negarects
    integralRect.size.height = max(integralRect.size.height, 0)

    return integralRect
}
#endif
