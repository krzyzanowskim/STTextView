//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//      |---contentView

import UIKit
import STTextKitPlus
import STTextViewCommon

@objc open class STTextView: UIScrollView {

    /// Sent when the selection range of characters changes.
    public static let didChangeSelectionNotification = STTextLayoutManager.didChangeSelectionNotification

    /// Posted before an object performs any operation that changes characters or formatting attributes.
    public static let textWillChangeNotification = NSNotification.Name("NSTextWillChangeNotification")

    /// Posted after an object performs any operation that changes characters or formatting attributes.
    public static let textDidChangeNotification = UITextView.textDidChangeNotification

    open var autocorrectionType: UITextAutocorrectionType = .default
    open var autocapitalizationType: UITextAutocapitalizationType = .sentences
    open var smartQuotesType: UITextSmartQuotesType = .default
    open var smartDashesType: UITextSmartDashesType = .default
    open var smartInsertDeleteType: UITextSmartInsertDeleteType = .default
    open var spellCheckingType: UITextSpellCheckingType = .default
    open var keyboardType: UIKeyboardType = .default
    open var keyboardAppearance: UIKeyboardAppearance = .default
    open var returnKeyType: UIReturnKeyType = .default

    /// The manager that lays out text for the text view's text container.
    @objc open private(set) var textLayoutManager: NSTextLayoutManager

    /// The text view's text storage object.
    @objc open private(set) var textContentManager: NSTextContentManager

    /// The text view's text container
    public var textContainer: NSTextContainer {
        get {
            textLayoutManager.textContainer!
        }

        set {
            textLayoutManager.textContainer = newValue
        }
    }

    /// A Boolean that controls whether the text container adjusts the width of its bounding rectangle when its text view resizes.
    ///
    /// When the value of this property is `true`, the text container adjusts its width when the width of its text view changes. The default value of this property is `false`.
    ///
    /// - Note: If you set both `widthTracksTextView` and `isHorizontallyResizable` up to resize automatically in the same dimension, your application can get trapped in an infinite loop.
    ///
    /// - SeeAlso: [Tracking the Size of a Text View](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html#//apple_ref/doc/uid/20000927-CJBBIAAF)
    @objc public var widthTracksTextView: Bool {
        set {
            if textContainer.widthTracksTextView != newValue {
                textContainer.widthTracksTextView = newValue
                textContainer.size = NSTextContainer().size

                setNeedsLayout()
                setNeedsDisplay()
            }
        }

        get {
            textContainer.widthTracksTextView
        }
    }

    /// A Boolean that controls whether the receiver changes its width to fit the width of its text.
    @objc public var isHorizontallyResizable: Bool {
        set {
            widthTracksTextView = newValue
        }

        get {
            widthTracksTextView
        }
    }

    /// When the value of this property is `true`, the text container adjusts its height when the height of its text view changes. The default value of this property is `false`.
    ///
    /// - Note: If you set both `heightTracksTextView` and `isVerticallyResizable` up to resize automatically in the same dimension, your application can get trapped in an infinite loop.
    ///
    /// - SeeAlso: [Tracking the Size of a Text View](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html#//apple_ref/doc/uid/20000927-CJBBIAAF)
    @objc public var heightTracksTextView: Bool {
        set {
            if textContainer.heightTracksTextView != newValue {
                textContainer.heightTracksTextView = newValue

                setNeedsLayout()
                setNeedsDisplay()
            }
        }

        get {
            textContainer.heightTracksTextView
        }
    }

    /// A Boolean that controls whether the receiver changes its height to fit the height of its text.
    @objc public var isVerticallyResizable: Bool {
        set {
            heightTracksTextView = newValue
        }

        get {
            heightTracksTextView
        }
    }

    /// The font of the text.
    ///
    /// This property applies to the entire text string.
    /// Assigning a new value to this property causes the new font to be applied to the entire contents of the text view.
    @objc dynamic open var font: UIFont? {
        get {
            // if not empty, return a font at location 0
            if !textLayoutManager.documentRange.isEmpty {
                let location = textLayoutManager.documentRange.location
                let endLocation = textLayoutManager.location(location, offsetBy: 1)
                return textLayoutManager.textContentManager?.attributedString(in: NSTextRange(location: location, end: endLocation))?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            }

            // otherwise return current typing attribute
            return typingAttributes[.font] as? UIFont
        }

        set {
            guard let newValue else {
                NSException(name: .invalidArgumentException, reason: "nil UIFont given").raise()
                return
            }

            if !textLayoutManager.documentRange.isEmpty {
                addAttributes([.font: newValue], range: textLayoutManager.documentRange)
            }

            typingAttributes[.font] = newValue
        }
    }

    /// The text color of the text view.
    @objc dynamic open var textColor: UIColor? {
        get {
            typingAttributes[.foregroundColor] as? UIColor
        }

        set {
            typingAttributes[.foregroundColor] = newValue
        }
    }

    /// Content view. Layout fragments content.
    internal let contentView: ContentView

    internal var fragmentViewMap: NSMapTable<NSTextLayoutFragment, STTextLayoutFragmentView>
    internal var baseWritingDirection: NSWritingDirection = .natural

    /// An input delegate that receives a notification when text changes or when the selection changes.
    ///
    /// The text input system automatically assigns a delegate to this property at runtime.
    public weak var inputDelegate: UITextInputDelegate?

    public var markedTextStyle: [NSAttributedString.Key : Any]?

    /// If text can be selected, it can be marked. Marked text represents provisionally
    /// inserted text that has yet to be confirmed by the user.  It requires unique visual
    /// treatment in its display.  If there is any marked text, the selection, whether a
    /// caret or an extended range, always resides within.
    ///
    /// Setting marked text either replaces the existing marked text or, if none is present,
    /// inserts it from the current selection.
    public var markedTextRange: UITextRange?

    /// A tokenizer must be provided to inform the text input system about text units of varying granularity.
    public lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)

    /// The text that the text view displays.
    public var text: String? {
        set {
            let prevLocation = textLayoutManager.insertionPointLocations.first

            setString(newValue)

            // restore selection location
            if let prevLocation {
                setSelectedTextRange(NSTextRange(location: prevLocation))
            }
        }

        get {
            textContentManager.attributedString(in: nil)?.string
        }
    }

    /// The styled text that the text view displays.
    ///
    /// Assigning a new value to this property also replaces the value of the `text` property with the same string data, albeit without any formatting information. In addition, the `font`, `textColor`, and `textAlignment` properties are updated to reflect the typing attributes of the text view.
    public var attributedText: NSAttributedString? {
        set {
            let prevLocation = textLayoutManager.insertionPointLocations.first

            setString(newValue)

            // restore selection location
            if let prevLocation {
                setSelectedTextRange(NSTextRange(location: prevLocation))
            }
        }

        get {
            textContentManager.attributedString(in: nil)
        }
    }

    /// A Boolean value that controls whether the text view allows the user to edit text.
    // @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isEditable: Bool {
        didSet {
            isSelectable = isEditable

            if !isEditable, isEditable != oldValue {
                _ = resignFirstResponder()
                updateEditableInteraction()
            }

        }
    }

    /// A Boolean value that controls whether the text views allows the user to select text.
    // @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isSelectable: Bool {
        didSet {
            if !isSelectable {
                isEditable = false
            }
        }
    }

    /// The receiver’s default paragraph style.
    @NSCopying @objc dynamic public var defaultParagraphStyle: NSParagraphStyle? {
        didSet {
            typingAttributes[.paragraphStyle] = defaultParagraphStyle ?? .default
        }
    }

    /// The attributes to apply to new text that the user enters.
    ///
    /// This dictionary contains the attribute keys (and corresponding values) to apply to newly typed text.
    /// When the text view’s selection changes, the contents of the dictionary are reset automatically.
    @objc dynamic public var typingAttributes: [NSAttributedString.Key: Any] {
        didSet {
            typingAttributes.merge(defaultTypingAttributes) { (current, _) in current }
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    

    internal func updateTypingAttributes(at location: NSTextLocation? = nil) {
        if let location {
            self.typingAttributes = typingAttributes(at: location)
        } else {
            // TODO: doesn't work work correctly (at all) for multiple insertion points where each has different typing attribute
            if let insertionPointSelection = textLayoutManager.insertionPointSelections.first,
               let startLocation = insertionPointSelection.textRanges.first?.location
            {
                self.typingAttributes = typingAttributes(at: startLocation)
            }
        }
    }

    internal func typingAttributes(at startLocation: NSTextLocation) -> [NSAttributedString.Key : Any] {
        guard !textLayoutManager.documentRange.isEmpty else {
            return typingAttributes
        }

        var attrs: [NSAttributedString.Key: Any] = [:]
        // The attribute is derived from the previous (upstream) location,
        // except for the beginning of the document where it from whatever is at location 0
        let options: NSTextContentManager.EnumerationOptions = startLocation == textLayoutManager.documentRange.location ? [] : [.reverse]
        let offsetDiff = startLocation == textLayoutManager.documentRange.location ? 0 : -1

        textContentManager.enumerateTextElements(from: startLocation, options: options) { textElement in
            if let attributedTextElement = textElement as? STAttributedTextElement,
               let elementRange = textElement.elementRange,
               let textContentManager = textElement.textContentManager
            {
                let offset = textContentManager.offset(from: elementRange.location, to: startLocation)
                assert(offset != NSNotFound, "Unexpected location")
                attrs = attributedTextElement.attributedString.attributes(at: offset + offsetDiff, effectiveRange: nil)
            }

            return false
        }

        // fill in with missing typing attributes if needed
        attrs.merge(defaultTypingAttributes, uniquingKeysWith: { current, _ in current})
        return attrs
    }

    private var defaultTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .paragraphStyle: self.defaultParagraphStyle ?? NSParagraphStyle.default,
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ]
    }

    private let editableTextInteraction = UITextInteraction(for: .editable)
    private let nonEditableTextInteraction = UITextInteraction(for: .nonEditable)

    @objc public var textInputView: UIView {
        self
    }

    open override var canBecomeFirstResponder: Bool {
        !isFirstResponder && isEditable
    }

    public convenience init(frame: CGRect, textContainer: NSTextContainer?) {
        self.init(frame: frame)
        textLayoutManager.textContainer = textContainer
    }

    public override init(frame: CGRect) {
        fragmentViewMap = .weakToWeakObjects()

        textContentManager = STTextContentStorage()
        textLayoutManager = STTextLayoutManager()

        textLayoutManager.textContainer = NSTextContainer()
        textLayoutManager.textContainer?.widthTracksTextView = false
        textLayoutManager.textContainer?.heightTracksTextView = true
        textContentManager.addTextLayoutManager(textLayoutManager)
        textContentManager.primaryTextLayoutManager = textLayoutManager

        isSelectable = true
        isEditable = true

        contentView = ContentView()
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        typingAttributes = [:]

        super.init(frame: frame)

        // Set insert point at the very beginning
        setSelectedTextRange(NSTextRange(location: textLayoutManager.documentRange.location))

        textLayoutManager.delegate = self
        textLayoutManager.textViewportLayoutController.delegate = self

        addSubview(contentView)

        editableTextInteraction.textInput = self
        editableTextInteraction.delegate = self

        nonEditableTextInteraction.textInput = self
        nonEditableTextInteraction.delegate = self

        updateEditableInteraction()

        NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            let textViewNotification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: notification.userInfo)

            NotificationCenter.default.post(textViewNotification)
            // self.delegateProxy.textViewDidChangeSelection(textViewNotification)
            // NSAccessibility.post(element: self, notification: .selectedTextChanged)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setSelectedTextRange(_ textRange: NSTextRange, updateLayout: Bool = true) {
        guard isSelectable, textRange.endLocation <= textLayoutManager.documentRange.endLocation else {
            return
        }

        selectedTextRange = textRange.uiTextRange

        updateTypingAttributes(at: textRange.location)

        if updateLayout {
            setNeedsLayout()
        }
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool = true) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        addAttributes(attrs, range: textRange, updateLayout: updateLayout)
    }

    /// Add attribute. Need `needsViewportLayout = true` to reflect changes.
    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentManager))
        }

        if updateLayout {
            updateTypingAttributes()
            setNeedsLayout()
        }
    }

    private func updateEditableInteraction() {

        func setupEditableInteraction() {
            if editableTextInteraction.view == nil {
                removeInteraction(nonEditableTextInteraction)
                addInteraction(editableTextInteraction)
            }
        }

        func setupNonEditableInteraction() {
            if nonEditableTextInteraction.view == nil {
                removeInteraction(editableTextInteraction)
                addInteraction(nonEditableTextInteraction)
            }
        }

        if isEditable {
            setupEditableInteraction()
        } else {
            setupNonEditableInteraction()
        }
    }

    internal func setString(_ string: Any?) {
        undoManager?.disableUndoRegistration()
        defer {
            undoManager?.enableUndoRegistration()
        }

        if case .some(let string) = string {
            switch string {
            case let attributedString as NSAttributedString:
                replaceCharacters(in: textLayoutManager.documentRange, with: attributedString, allowsTypingCoalescing: false)
            case let string as String:
                replaceCharacters(in: textLayoutManager.documentRange, with: string, useTypingAttributes: true, allowsTypingCoalescing: false)
            default:
                assertionFailure()
                return
            }
        } else if case .none = string {
            replaceCharacters(in: textLayoutManager.documentRange, with: "", useTypingAttributes: true, allowsTypingCoalescing: false)
        }
    }

    open override func sizeToFit() {
        super.sizeToFit()
        contentView.frame.size = contentSize

        _configureTextContainerSize()

        // Estimate `usageBoundsForTextContainer` size is based on performed layout.
        // If layout didn't happen for the whole document, it only cover
        // the fragment that is known. And even after ensureLayout for the whole document
        // `textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)`
        // it can't report exact size (it must do internal estimations then).
        //
        // Because I use "lazy layout" with the viewport, there is no "layout everything"
        // on launch (due to performance reason) hence the total size is not know in advance.
        // TextKit estimate the usageBoundsForTextContainer until everything is layed out
        // that may result in weird and unexpected values along the way
        //
        // Calling ensureLayout on the whole document should fix the value, however
        // it may be time consuming (in seconds) hence not recommended:
        // textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
        //
        // Asking for the end location result in estimated `usageBoundsForTextContainer`
        // that eventually get right as more and more layout happen (when scrolling)

        textLayoutManager.ensureLayout(for: NSTextRange(location: textLayoutManager.documentRange.endLocation))
    }

    // Update textContainer width to match textview width if track textview width
    // widthTracksTextView = true
    private func _configureTextContainerSize() {
        var containerSize = textContainer.size
        if !isHorizontallyResizable {
            containerSize.width = bounds.size.width // - _textContainerInset.width * 2
        }

        if !isVerticallyResizable {
            containerSize.height = bounds.size.height // - _textContainerInset.height * 2
        }

        if !textContainer.size.isAlmostEqual(to: containerSize)  {
            textContainer.size = containerSize
        }
    }

    /// Whenever text is to be changed due to some user-induced action,
    /// this method should be called with information on the change.
    /// Coalesce consecutive typing events
    open func shouldChangeText(in affectedTextRange: NSTextRange, replacementString: String?) -> Bool {
        //let result = delegateProxy.textView(self, shouldChangeTextIn: affectedTextRange, replacementString: replacementString)
        //if !result {
        //    return result
        //}
        //
        //return result
        // TODO
        return true
    }

    internal func shouldChangeText(in affectedTextRanges: [NSTextRange], replacementString: String?) -> Bool {
        affectedTextRanges.allSatisfy { textRange in
            shouldChangeText(in: textRange, replacementString: replacementString)
        }
    }

    public func replaceCharacters(in range: NSTextRange, with string: String) {
        replaceCharacters(in: range, with: string, useTypingAttributes: true, allowsTypingCoalescing: false)
    }

    internal func replaceCharacters(in textRanges: [NSTextRange], with replacementString: String, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        self.replaceCharacters(
            in: textRanges,
            with: NSAttributedString(string: replacementString, attributes: useTypingAttributes ? typingAttributes : [:]),
            allowsTypingCoalescing: allowsTypingCoalescing
        )
    }

    internal func replaceCharacters(in textRanges: [NSTextRange], with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        // Replace from the end to beginning of the document
        for textRange in textRanges.sorted(by: { $0.location > $1.location }) {
            replaceCharacters(in: textRange, with: replacementString, allowsTypingCoalescing: true)
        }
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: String, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        self.replaceCharacters(
            in: textRange,
            with: NSAttributedString(string: replacementString, attributes: useTypingAttributes ? typingAttributes : [:]),
            allowsTypingCoalescing: allowsTypingCoalescing
        )
    }

    open func textWillChange(_ sender: Any?) {
        let notification = Notification(name: Self.textWillChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)

        inputDelegate?.textWillChange(self)
        // delegateProxy.textViewWillChangeText(notification)
    }

    /// Sends out necessary notifications when a text change completes.
    ///
    /// Invoked automatically at the end of a series of changes, this method posts an `textDidChangeNotification` to the default notification center, which also results in the delegate receiving `textViewDidChangeText(_:)` message.
    /// Subclasses implementing methods that change their text should invoke this method at the end of those methods.
    open func didChangeText() {
        let notification = Notification(name: Self.textDidChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)

        inputDelegate?.textDidChange(self)
        // delegateProxy.textViewDidChangeText(notification)

    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        textWillChange(self)
        //delegateProxy.textView(self, willChangeTextIn: textRange, replacementString: replacementString.string)

        textContentManager.performEditingTransaction {
            textContentManager.replaceContents(
                in: textRange,
                with: [NSTextParagraph(attributedString: replacementString)]
            )
        }

        //delegateProxy.textView(self, didChangeTextIn: textRange, replacementString: replacementString.string)
        didChangeText()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layoutViewport()
    }

    private func layoutViewport() {
        // layoutViewport does not handle properly layout range
        // for far jump it tries to layout everything starting at location 0
        // even though viewport range is properly calculated.
        // No known workaround.
        textLayoutManager.textViewportLayoutController.layoutViewport()
    }
}
