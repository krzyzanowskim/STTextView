import Foundation
import SwiftUI

public protocol STCompletionItem: Identifiable {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}
