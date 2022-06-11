import Foundation

public enum STCompletion {

    public class Item: Identifiable {

        public let id: String
        public let label: String
        public let insertText: String

        public init(id: String, label: String, insertText: String) {
            self.id = id
            self.label = label
            self.insertText = insertText
        }
    }

}
