import Foundation

#if os(macOS)
    @_exported import STTextViewAppKit
#endif

#if os(iOS) || targetEnvironment(macCatalyst)
    @_exported import STTextViewUIKit
#endif

@_exported import STTextViewCommon

