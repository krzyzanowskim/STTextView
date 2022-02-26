import Cocoa

extension NSResponder {
    var responderChain: [NSResponder] {
        Array(sequence(first: self, next: \.nextResponder))
    }
}
