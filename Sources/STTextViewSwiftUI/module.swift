import Foundation

#if os(macOS)
    @_exported import STTextViewSwiftUIAppKit
#endif

#if os(iOS) || targetEnvironment(macCatalyst)
    @_exported import STTextViewSwiftUIUIKit
#endif
