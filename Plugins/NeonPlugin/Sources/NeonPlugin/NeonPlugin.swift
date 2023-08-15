import Cocoa

import STTextView
import STTextKitPlus

import Neon
import TreeSitterClient
import SwiftTreeSitter

// Swift
import TreeSitterSwift

public struct NeonPlugin: STPlugin {

    public init() { }

    public func setUp(context: Context) {

        context.events.onWillChangeText { affectedRange in
            let range = NSRange(affectedRange, in: context.textView.textContentManager)
            context.coordinator.willChangeContent(in: range)
        }

        context.events.onDidChangeText { affectedRange, replacementString in
            guard let replacementString else { return }

            let range = NSRange(affectedRange, in: context.textView.textContentManager)
            let str = context.textView.string
            context.coordinator.didChangeContent(to: str, in: range, delta: replacementString.utf16.count - range.length, limit: str.utf16.count)
        }
    }

    public func makeCoordinator(context: CoordinatorContext) -> Coordinator {
        Coordinator(textView: context.textView)
    }

    public class Coordinator {
        private var highlighter: Neon.Highlighter?
        private let tsLanguage: SwiftTreeSitter.Language
        private let tsClient: TreeSitterClient

        init(textView: STTextView) {
            tsLanguage = Language(language: tree_sitter_swift())

            tsClient = try! TreeSitterClient(language: tsLanguage) { codePointIndex in
                guard let location = textView.textContentManager.location(at: codePointIndex),
                      let position = textView.textContentManager.position(location)
                else {
                    return .zero
                }

                return Point(row: position.row, column: position.column)
            }

            tsClient.invalidationHandler = { [weak self] indexSet in
                guard let self = self else { return }
                // Invalidate ctags
                Task { @MainActor in
                    self.highlighter?.invalidate(.set(indexSet))
                }
            }

            highlighter = Neon.Highlighter(textInterface: STTextViewSystemInterface(textView: textView) { neonToken in
                switch neonToken.name {
                case "string":
                    return [.foregroundColor: NSColor.systemRed]
                case "keyword", "include", "constructor", "keyword.function", "keyword.return", "variable.builtin", "boolean":
                    return [.foregroundColor: NSColor.systemPink]
                case "type":
                    return [.foregroundColor: NSColor.systemBrown]
                case "function.call":
                    return [.foregroundColor: NSColor.systemIndigo]
                case "variable", "method", "parameter":
                    return [.foregroundColor: NSColor.systemTeal]
                case "comment":
                    return [.foregroundColor: NSColor.systemGray]
                default:
                    return [:]
                }
            }, tokenProvider: tokenProvider(textContentManager: textView.textContentManager))
        }

        private func tokenProvider(textContentManager: NSTextContentManager) -> Neon.TokenProvider? {

            let url = Bundle.main.resourceURL!.appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle").appendingPathComponent("Contents/Resources/queries/highlights.scm")

            guard let highlightsQuery = try? tsLanguage.query(contentsOf: url) else {
                return nil
            }

            return tsClient.tokenProvider(with: highlightsQuery) { range, _ in
                textContentManager.attributedString(in: NSTextRange(range, provider: textContentManager))?.string
            }
        }

        func willChangeContent(in range: NSRange) {
            tsClient.willChangeContent(in: range)
        }

        func didChangeContent(to string: String, in range: NSRange, delta: Int, limit: Int) {
            tsClient.didChangeContent(to: string, in: range, delta: delta, limit: limit)
        }

    }

}
