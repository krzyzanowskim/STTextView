import Foundation

#if os(macOS)
@_exported import STTextViewMac
#endif

#if os(iOS)
@_exported import STTextViewUIKit
#endif
