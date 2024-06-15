//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit

// These methods suppose that ranges of text in the document may have attached to them certain annotations relevant for text checking,
// represented by dictionaries with various keys, such as NSSpellingStateAttributeName or ranges of text marked as misspelled.
// They allow an NSTextCheckingController instance to set and retrieve these annotations, and to perform other actions required for text checking.
// The keys and values in these annotation dictionaries will always be strings.
//
// In all of these methods, the standard range adjustment policy is as follows:
//   - If the specified range lies only partially within the bounds of the document, the receiver is responsible for adjusting the range so as to limit it to the bounds of the document.
//   - If the specified range is {NSNotFound, 0}, then the receiver should replace it with the entire range of the document.
//   - Otherwise, if none of the range lies within the bounds of the document, then these methods should have no effect, and return nil where appropriate.
//
// The beginning and end of the document are not considered as lying outside of the bounds of the document, and zero-length ranges are acceptable (although in some cases they may have no effect).
extension STTextView: NSTextCheckingClient {

    private func adjustedRange(_ range: NSRange) -> NSRange? {
        var adjRange = range

        // If the specified range is {NSNotFound, 0}, then the receiver should replace it with the entire range of the document.
        if adjRange == .notFound {
            adjRange = NSRange(textLayoutManager.documentRange, in: textContentManager)
        }

        guard var adjRange = adjRange.clamped(NSRange(textLayoutManager.documentRange, in: textContentManager)) else {
            return nil
        }

        // Expand to the end of paragraph (if apply). The original range has arbitrary length (1024 chunks)
        if let selectionTextRange = NSTextRange(adjRange, in: textContentManager) {
            let paragraphTextRange = textLayoutManager.textSelectionNavigation.textSelection(
                for: .paragraph,
                enclosing: NSTextSelection(selectionTextRange.endLocation, affinity: .upstream)
            ).textRanges.reduce(selectionTextRange) { partialResult, textRange in
                partialResult.union(textRange)
            }

            adjRange = NSRange(paragraphTextRange, in: textContentManager)
        }

        return adjRange
    }


    // Returns annotated string specified by range.
    //
    // The range should be adjusted according to the standard range adjustment policy, and in addition for this method alone it should be adjusted to begin and end on paragraph boundaries
    // (with possible exceptions for paragraphs exceeding some maximum length).
    //
    // If the range lies within the bounds of the document but is of zero length, it should be adjusted to include the enclosing paragraph.
    //
    // This method should return nil if none of the range lies within the bounds of the document,
    // but if only a zero-length portion of the adjusted range lies within the bounds of the document,
    // as may happen with an empty document or at the end of the document, then an empty attributed string should be returned rather than nil.
    //
    // If the return value is non-nil and actualRange is non-NULL, then actualRange returns the actual adjusted range used.
    public func annotatedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        guard let range = adjustedRange(range) else {
            return nil
        }

        if range.length == 0 {
            // If the range lies within the bounds of the document but is of zero length, it should be adjusted to include the enclosing paragraph.
            return NSAttributedString("")
        }

        let attributedString = self.attributedSubstring(forProposedRange: range, actualRange: actualRange)?.mutableCopy() as! NSMutableAttributedString
        let actualRange = actualRange?.pointee ?? range
        guard let actualTextRange = NSTextRange(actualRange, in: textContentManager) else {
            return nil
        }

        // strip out attributes except what's valid (textCheckingController.validAnnotations())
        let invalidAttributes = attributedString.attributes(in: attributedString.range, options: .longestEffectiveRangeNotRequired).subtracting(textCheckingController.validAnnotations())
        for attr in invalidAttributes {
            attributedString.removeAttribute(attr, range: attributedString.range)
        }

        // add (apply) spellcheck attributes from rendering attributes where annotations are saved
        let offset = textContentManager.offset(from: textLayoutManager.documentRange.location, to: actualTextRange.location)
        textLayoutManager.enumerateRenderingAttributes(in: actualTextRange, reverse: false) { textLayoutManager, attrs, attrTextRange in
            for spellcheckAttributeKey in attrs.keys.filter({ textCheckingController.validAnnotations().contains($0) }) {
                guard let value = attrs[spellcheckAttributeKey],
                      let loc = textContentManager.location(attrTextRange.location, offsetBy: -offset),
                      let endLoc = textContentManager.location(attrTextRange.endLocation, offsetBy: -offset),
                      let adjustedAttrTextRange = NSTextRange(location: loc, end: endLoc)
                else {
                    continue
                }
                attributedString.addAttribute(spellcheckAttributeKey, value: value, range: NSRange(adjustedAttrTextRange, in: textContentManager))
            }
            return true
        }

        return attributedString
    }

    private func addRenderingAnnotations(_ annotations: [NSAttributedString.Key: String], range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }

        for annotation in annotations {
            textLayoutManager.addRenderingAttribute(annotation.key, value: annotation.value, for: textRange)
        }
    }

    // The receiver replaces any existing annotations on the specified range with the provided annotations.
    // The range should be adjusted according to the standard range adjustment policy.
    //
    // Has no effect if the adjusted range has zero length.
    public func setAnnotations(_ annotations: [NSAttributedString.Key : String], range: NSRange) {
        guard range.length > 0 else {
            return
        }

        addRenderingAnnotations(annotations, range: range)
    }

    public func addAnnotations(_ annotations: [NSAttributedString.Key : String], range: NSRange) {
        addRenderingAnnotations(annotations, range: range)
    }

    public func removeAnnotation(_ annotationName: NSAttributedString.Key, range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }

        textLayoutManager.removeRenderingAttribute(annotationName, for: textRange)
    }

    public func replaceCharacters(in range: NSRange, withAnnotatedString annotatedString: NSAttributedString) {
        self.replaceCharacters(in: range, with: annotatedString.string)
    }

    public func selectAndShow(_ range: NSRange) {
        self.scrollRangeToVisible(range)
        self.setSelectedRange(range)
    }

    // Returns the view displaying the first logical area for range, and the corresponding rect in view coordinates.
    //
    // The range should be adjusted according to the standard range adjustment policy.
    // May return nil if the range is not being displayed, or if none of the range lies within the bounds of the document.
    //
    // A zero-length selection corresponds to an insertion point, and this should return an appropriate view and rect if the adjusted range is of zero length,
    // provided it lies within the bounds of the document (including at the end of the document) and is being displayed.
    //
    // If the return value is non-nil and actualRange is non-NULL, then actualRange returns the range of text displayed in the returned rect.
    public func view(for range: NSRange, firstRect: NSRectPointer?, actualRange: NSRangePointer?) -> NSView? {
        let range = adjustedRange(range) ?? range
        actualRange?.pointee = range
        return self
    }

    @_implements(NSTextCheckingClient, candidateListTouchBarItem())
    public func candidateListTouchBarItem_NSTextCheckingClient() -> NSCandidateListTouchBarItem<AnyObject>? {
        super.candidateListTouchBarItem
    }

}

extension STTextView {

    @objc public var spellCheckerDocumentTag: Int {
        textCheckingController.spellCheckerDocumentTag
    }

    @objc public func checkTextInDocument(_ sender: Any?) {
        textCheckingController.checkTextInDocument(sender)
    }

    @objc public func checkTextInSelection(_ sender: Any?) {
        textCheckingController.checkTextInSelection(sender)
    }

    @objc public func checkText(in range: NSRange, types checkingTypes: NSTextCheckingTypes, options: [NSSpellChecker.OptionKey : Any] = [:]) {
        textCheckingController.checkText(in: range, types: checkingTypes, options: options)
    }

    @objc public func checkSpelling(_ sender: Any?) {
        textCheckingController.checkSpelling(sender)
    }

    @objc public func toggleContinuousSpellChecking(_ sender: Any?) {
        isContinuousSpellCheckingEnabled.toggle()
        NSSpellChecker.shared.updatePanels()
    }

    @objc public func toggleGrammarChecking(_ sender: Any?) {
        isGrammarCheckingEnabled.toggle()
        NSSpellChecker.shared.updatePanels()
    }

    @objc public func toggleAutomaticSpellingCorrection(_ sender: Any?) {
        isAutomaticSpellingCorrectionEnabled.toggle()
        NSSpellChecker.shared.updatePanels()
    }

    @objc public func toggleAutomaticTextCompletion(_ sender: Any?) {
        isAutomaticTextCompletionEnabled.toggle()
        NSSpellChecker.shared.updatePanels()
    }

    @objc public func toggleAutomaticQuoteSubstitution(_ sender: Any?) {
        isAutomaticQuoteSubstitutionEnabled.toggle()
        NSSpellChecker.shared.updatePanels()
    }

    @objc public func showGuessPanel(_ sender: Any?) {
        textCheckingController.showGuessPanel(sender)
    }

    @objc public func orderFrontSubstitutionsPanel(_ sender: Any?) {
        textCheckingController.orderFrontSubstitutionsPanel(sender)
    }

    @objc func considerTextChecking(for range: NSRange) {
        textCheckingController.considerTextChecking(for: range)
    }

}

extension STTextView {

    /// To be called after text is changed.
    internal func textCheckingDidChangeText(in range: NSRange) {

        // Doesn't seem to trigger anything
        textCheckingController.didChangeText(in: range)

        // So do manually
        // uncheck. remove spelling attributes in the word on both sides
        if let textRange = NSTextRange(range, in: textContentManager) {
            textLayoutManager.enumerateRenderingAttributes(from: textRange.location, reverse: true) { textLayoutManager, attributes, attributesTextRange in
                for attribute in attributes where textCheckingController.validAnnotations().contains(where: { $0 == attribute.key }) {
                    textLayoutManager.removeRenderingAttribute(attribute.key, for: attributesTextRange)
                }
                return false
            }

            textLayoutManager.enumerateRenderingAttributes(from: textRange.location, reverse: false) { textLayoutManager, attributes, attributesTextRange in
                for attribute in attributes where textCheckingController.validAnnotations().contains(where: { $0 == attribute.key }) {
                    textLayoutManager.removeRenderingAttribute(attribute.key, for: attributesTextRange)
                }
                return false
            }
        }
    }

}

extension STTextView: NSTextInputTraits {

    @objc public var spellCheckingType: NSTextInputTraitType {
        get {
            isContinuousSpellCheckingEnabled ? .yes : .no
        }
        set {
            isContinuousSpellCheckingEnabled = newValue == .yes
        }
    }

    @objc public var autocorrectionType: NSTextInputTraitType {
        get {
            isAutomaticSpellingCorrectionEnabled ? .yes : .no
        }
        set {
            isAutomaticSpellingCorrectionEnabled = newValue == .yes
        }
    }

    @objc public var grammarCheckingType: NSTextInputTraitType {
        get {
            isGrammarCheckingEnabled ? .yes : .no
        }

        set {
            isGrammarCheckingEnabled = newValue == .yes
        }
    }

    @objc public var textCompletionType: NSTextInputTraitType {
        get {
            isAutomaticTextCompletionEnabled ? .yes : .no
        }

        set {
            isAutomaticTextCompletionEnabled = newValue == .yes
        }
    }

    @objc public var textReplacementType: NSTextInputTraitType {
        get {
            isAutomaticTextReplacementEnabled ? .yes : .no
        }

        set {
            isAutomaticTextCompletionEnabled = newValue == .yes
        }
    }

    @objc public var smartQuotesType: NSTextInputTraitType {
        get {
            isAutomaticQuoteSubstitutionEnabled ? .yes : .no
        }

        set {
            isAutomaticQuoteSubstitutionEnabled = newValue == .yes
        }
    }

}

extension STTextView: NSChangeSpelling {

    public func changeSpelling(_ sender: Any?) {
        textCheckingController.changeSpelling(sender)
    }

}

extension STTextView: NSIgnoreMisspelledWords {

    public func ignoreSpelling(_ sender: Any?) {
        textCheckingController.ignoreSpelling(sender)
    }

}

private extension NSRange {
    func clamped(_ limits: NSRange) -> Self? {
        guard let limits = Range(limits),
              let clampedRange = Range(self)?.clamped(to: limits)
        else {
            return nil
        }

        return Self(clampedRange)
    }
}
