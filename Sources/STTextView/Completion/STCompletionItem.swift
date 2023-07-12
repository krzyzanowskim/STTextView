import Foundation
import SwiftUI

public protocol STCompletionItem: Identifiable {
    var view: NSView { get }
}
