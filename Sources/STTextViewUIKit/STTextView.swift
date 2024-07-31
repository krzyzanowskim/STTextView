//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//      |---ContentView
//              |---STLineHighlightView
//              |---STTextLayoutFragmentView
//      |---STRulerView

import UIKit
import STTextKitPlus
import STTextViewCommon

@objc open class STTextView: UIScrollView, STTextViewProtocol {

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

    /// A Boolean that controls whether the text view highlights the currently selected line. Default false.
    @Invalidating(.layout)
    @objc dynamic open var highlightSelectedLine: Bool = false

    /// Enable to show line numbers in the gutter.
    @Invalidating(.layout)
    open var showLineNumbers: Bool = false {
        didSet {
            isRulerVisible = showLineNumbers
        }
    }

    /// The highlight color of the selected line.
    ///
    /// Note: Needs ``highlightSelectedLine`` to be set to `true`
    @Invalidating(.display)
    @objc dynamic open var selectedLineHighlightColor: UIColor = UIColor.tintColor.withAlphaComponent(0.15)

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

    /// Gutter view
    public var gutterView: STRulerView? {
        rulerView
    }

    /// Installed plugins. events value is available after plugin is setup
    internal var plugins: [Plugin] = []

    /// Content view. Layout fragments content.
    internal let contentView: ContentView
    internal let lineHighlightView: STLineHighlightView
    internal var rulerView: STRulerView?

    internal var fragmentViewMap: NSMapTable<NSTextLayoutFragment, STTextLayoutFragmentView>

    /// The delegate for all text views sharing the same layout manager.
    public weak var textDelegate: (any STTextViewDelegate)? {
        set {
            delegateProxy.source = newValue
        }

        get {
            delegateProxy.source
        }
    }

    /// Proxy for delegate calls
    internal let delegateProxy = STTextViewDelegateProxy(source: nil)

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
    public var markedTextRange: UITextRange? {
        if let markedText, let textRange = NSTextRange(markedText.markedRange, in: textContentManager) {
            return STTextLocationRange(textRange: textRange)
        }

        return nil
    }
    
    internal var markedText: STMarkedText? = nil

    /// A tokenizer must be provided to inform the text input system about text units of varying granularity.
    public lazy var tokenizer: UITextInputTokenizer = STTextInputTokenizer(textLayoutManager)

    /// The text that the text view displays.
    public var text: String? {
        set {
            let prevLocation = textLayoutManager.insertionPointLocations.first

            setString(newValue)

            if let prevLocation {
                // restore selection location
                setSelectedTextRange(NSTextRange(location: prevLocation))
            } else {
                // or try to set at the begining of the document
                setSelectedTextRange(NSTextRange(location: textContentManager.documentRange.location))
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

            if let prevLocation {
                // restore selection location
                setSelectedTextRange(NSTextRange(location: prevLocation))
            } else {
                // or try to set at the begining of the document
                setSelectedTextRange(NSTextRange(location: textContentManager.documentRange.location))
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

    // line height based on current typing font and current typing paragraph
    internal var typingLineHeight: CGFloat {
        let font = typingAttributes[.font] as? UIFont ?? self.defaultTypingAttributes[.font] as! UIFont
        let paragraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? self.defaultTypingAttributes[.paragraphStyle] as! NSParagraphStyle
        let lineHeightMultiple = paragraphStyle.lineHeightMultiple.isAlmostZero() ? 1.0 : paragraphStyle.lineHeightMultiple
        return calculateDefaultLineHeight(for: font) * lineHeightMultiple
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

        lineHighlightView = STLineHighlightView()
        lineHighlightView.isHidden = true

        typingAttributes = [:]

        super.init(frame: frame)

        textLayoutManager.delegate = self
        textLayoutManager.textViewportLayoutController.delegate = self

        addSubview(contentView)
        contentView.addSubview(lineHighlightView)

        editableTextInteraction.textInput = self
        editableTextInteraction.delegate = self

        nonEditableTextInteraction.textInput = self
        nonEditableTextInteraction.delegate = self

        updateEditableInteraction()
        isRulerVisible = showLineNumbers

        NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            let textViewNotification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: notification.userInfo)

            NotificationCenter.default.post(textViewNotification)
            self.delegateProxy.textViewDidChangeSelection(textViewNotification)
            // NSAccessibility.post(element: self, notification: .selectedTextChanged)
        }
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view
    @objc public func toggleRuler(_ sender: Any?) {
        isRulerVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    public var isRulerVisible: Bool {
        set {
            if rulerView == nil, newValue == true {
                rulerView = STRulerView()
                if let font {
                    rulerView?.font = font
                }
                rulerView?.frame.size.width = 40
                if let textColor {
                    rulerView?.selectedLineTextColor = textColor
                }
                rulerView?.highlightSelectedLine = highlightSelectedLine
                rulerView?.selectedLineHighlightColor = selectedLineHighlightColor
                self.addSubview(rulerView!)
            } else if newValue == false {
                rulerView?.removeFromSuperview()
                rulerView = nil
            }
        }
        get {
            rulerView != nil
        }
    }

    public func setSelectedTextRange(_ textRange: NSTextRange, updateLayout: Bool = true) {
        guard isSelectable, textRange.endLocation <= textLayoutManager.documentRange.endLocation else {
            return
        }

        selectedTextRange = textRange.uiTextRange

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

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool = true) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        setAttributes(attrs, range: textRange, updateLayout: updateLayout)
    }

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.setAttributes(attrs, range: NSRange(range, in: textContentManager))
        }


        if updateLayout {
            updateTypingAttributes()
            setNeedsLayout()
        }
    }

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    open func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange, updateLayout: Bool = true) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        removeAttribute(attribute, range: textRange, updateLayout: updateLayout)
    }

    /// Set attributes. Need `needsViewportLayout = true` to reflect changes.
    open func removeAttribute(_ attribute: NSAttributedString.Key, range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.removeAttribute(attribute, range: NSRange(range, in: textContentManager))
        }

        updateTypingAttributes()

        if updateLayout {
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
        contentView.bounds.origin.x = -(rulerView?.frame.width ?? 0)
        contentView.frame.size.width = max(textLayoutManager.usageBoundsForTextContainer.size.width, bounds.width - (rulerView?.frame.width ?? 0))
        contentView.frame.size.height = max(textLayoutManager.usageBoundsForTextContainer.size.height, bounds.height)
        contentSize = contentView.frame.size

        super.sizeToFit()

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
            containerSize.width = contentSize.width // - _textContainerInset.width * 2
        }

        if !isVerticallyResizable {
            containerSize.height = contentSize.height // - _textContainerInset.height * 2
        }

        if !textContainer.size.isAlmostEqual(to: containerSize)  {
            textContainer.size = containerSize
        }
    }

    /// Whenever text is to be changed due to some user-induced action,
    /// this method should be called with information on the change.
    /// Coalesce consecutive typing events
    open func shouldChangeText(in affectedTextRange: NSTextRange, replacementString: String?) -> Bool {
        let result = delegateProxy.textView(self, shouldChangeTextIn: affectedTextRange, replacementString: replacementString)
        if !result {
            return result
        }
        
        return result
    }

    internal func shouldChangeText(in affectedTextRanges: [NSTextRange], replacementString: String?) -> Bool {
        affectedTextRanges.allSatisfy { textRange in
            shouldChangeText(in: textRange, replacementString: replacementString)
        }
    }

    open func replaceCharacters(in range: NSTextRange, with string: String) {
        replaceCharacters(in: range, with: string, useTypingAttributes: true, allowsTypingCoalescing: false)
    }

    open func insertText(_ string: Any, replacementRange: NSRange) {
        unmarkText()

        var textRanges: [NSTextRange] = []

        if replacementRange == .notFound {
            textRanges = textLayoutManager.textSelections.flatMap(\.textRanges)
        }

        let replacementTextRange = NSTextRange(replacementRange, in: textContentManager)
        if let replacementTextRange, !textRanges.contains(where: { $0 == replacementTextRange }) {
            textRanges.append(replacementTextRange)
        }

        switch string {
        case let string as String:
            if shouldChangeText(in: textRanges, replacementString: string) {
                replaceCharacters(in: textRanges, with: string, useTypingAttributes: true, allowsTypingCoalescing: true)
            }
        case let attributedString as NSAttributedString:
            if shouldChangeText(in: textRanges, replacementString: attributedString.string) {
                replaceCharacters(in: textRanges, with: attributedString, allowsTypingCoalescing: true)
            }
        default:
            assertionFailure()
        }
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

    public func textWillChange(_ sender: Any?) {
        inputDelegate?.textWillChange(self)

        let notification = Notification(name: Self.textWillChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)

        delegateProxy.textViewWillChangeText(notification)
    }

    /// Sends out necessary notifications when a text change completes.
    ///
    /// Invoked automatically at the end of a series of changes, this method posts an `textDidChangeNotification` to the default notification center, which also results in the delegate receiving `textViewDidChangeText(_:)` message.
    /// Subclasses implementing methods that change their text should invoke this method at the end of those methods.
    public func didChangeText() {
        let notification = Notification(name: Self.textDidChangeNotification, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)

        inputDelegate?.textDidChange(self)
        delegateProxy.textViewDidChangeText(notification)
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        textWillChange(self)
        delegateProxy.textView(self, willChangeTextIn: textRange, replacementString: replacementString.string)

        textContentManager.performEditingTransaction {
            textContentManager.replaceContents(
                in: textRange,
                with: [NSTextParagraph(attributedString: replacementString)]
            )
        }

        delegateProxy.textView(self, didChangeTextIn: textRange, replacementString: replacementString.string)
        didChangeText()
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copy(_:)):
            return selectedTextRange?.isEmpty == false
        case #selector(cut(_:)):
            return isEditable && selectedTextRange?.isEmpty == false
        case #selector(selectAll(_:)):
            return isSelectable
//        case #selector(select(_:)):
//            return isSelectable
        case #selector(paste(_:)):
            return isEditable && UIPasteboard.general.hasStrings
        case #selector(replace(_:)):
            return isEditable
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layoutViewport()
        layoutLineHighlight()
        layoutRuler()
        layoutLineNumbers()
    }

    private func layoutRuler() {
        rulerView?.frame.origin = contentOffset
        rulerView?.frame.size.height = visibleSize.height
    }

    private func layoutViewport() {
        // layoutViewport does not handle properly layout range
        // for far jump it tries to layout everything starting at location 0
        // even though viewport range is properly calculated.
        // No known workaround.
        textLayoutManager.textViewportLayoutController.layoutViewport()
    }

    private func layoutLineHighlight() {
        guard highlightSelectedLine,
              textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty,
              !textLayoutManager.insertionPointSelections.isEmpty
        else {
            // don't highlight when there's selection
            lineHighlightView.isHidden = true
            return
        }

        lineHighlightView.isHidden = false
        lineHighlightView.backgroundColor = selectedLineHighlightColor

        if textLayoutManager.documentRange.isEmpty {
            // - empty document has no layout fragments, nothing, it's empty and has to be handled explicitly.
            // - there's no layout fragment at the document endLocation (technically it's out of bounds), has to be handled explicitly.
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                lineHighlightView.frame = CGRect(
                    origin: CGPoint(
                        x: contentView.frame.origin.x,
                        y: selectionFrame.origin.y
                    ),
                    size: CGSize(
                        width: contentView.frame.width,
                        height: typingLineHeight
                    )
                )
            }
            return
        }

        guard let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return
        }

        // build the rectangle out of fragments rectangles
        var combinedFragmentsRect: CGRect?

        // TODO some beutiful day:
        // Don't rely on NSTextParagraph.paragraphContentRange, but that
        // makes tricky to get all the conditions right (especially for last line)
        // Problem is that NSTextParagraph.rangeInElement span across two lines (eg. "abc\n" are two lines) while
        // paragraphContentRange is just one ("abc")
        //
        // Another idea here is to use `textLayoutManager.textLayoutFragment(for: selectionTextRange.location)`
        // to find the layout fragment and us its frame as highlight area. It has its issue when it comes to the
        // extra line fragment area (sic).
        textLayoutManager.enumerateTextLayoutFragments(in: viewportRange) { layoutFragment in
            let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement
            for lineFragment in layoutFragment.textLineFragments {

                func isLineSelected() -> Bool {
                    textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
                        var result = true
                        if lineFragment.isExtraLineFragment {
                            let c1 = layoutFragment.rangeInElement.endLocation == selectionTextRange.location
                            result = result && c1
                        } else {
                            let c1 = contentRangeInElement.contains(selectionTextRange)
                            let c2 = contentRangeInElement.intersects(selectionTextRange)
                            let c3 = selectionTextRange.contains(contentRangeInElement)
                            let c4 = selectionTextRange.intersects(contentRangeInElement)
                            let c5 = contentRangeInElement.endLocation == selectionTextRange.location
                            result = result && (c1 || c2 || c3 || c4 || c5)
                        }
                        return partialResult && result
                    }
                }

                let isLineSelected = isLineSelected()

                if isLineSelected {
                    var lineFragmentFrame = layoutFragment.layoutFragmentFrame
                    lineFragmentFrame.size.height = lineFragment.typographicBounds.height


                    let r = CGRect(
                        origin: CGPoint(
                            x: contentView.frame.origin.x,
                            y: lineFragmentFrame.origin.y + lineFragment.typographicBounds.minY
                        ),
                        size: CGSize(
                            width: contentView.frame.size.width,
                            height: lineFragmentFrame.height
                        )
                    )

                    if let rect = combinedFragmentsRect {
                        combinedFragmentsRect = rect.union(r)
                    } else {
                        combinedFragmentsRect = r
                    }
                }
            }
            return true
        }

        if let combinedFragmentsRect {
            lineHighlightView.frame = combinedFragmentsRect.pixelAligned
        }

    }

    private func layoutLineNumbers() {
        guard let rulerView, let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return
        }

        rulerView.lineNumberViewContainer.subviews.forEach { v in
            v.removeFromSuperview()
        }

        let textElements = textContentManager.textElements(
            for: NSTextRange(
                location: textLayoutManager.documentRange.location,
                end: viewportRange.location
            )!
        )

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: rulerView.font,
            .foregroundColor: UIColor.secondaryLabel.cgColor
        ]

        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (rulerView.selectedLineTextColor ?? rulerView.textColor).cgColor
        ]

        let startLineIndex = textElements.count
        var linesCount = 0
        textLayoutManager.enumerateTextLayoutFragments(in: viewportRange) { layoutFragment in
            let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

            for lineFragment in layoutFragment.textLineFragments where (lineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == lineFragment) {

                func isLineSelected() -> Bool {
                    textLayoutManager.textSelections.flatMap(\.textRanges).reduce(true) { partialResult, selectionTextRange in
                        var result = true
                        if lineFragment.isExtraLineFragment {
                            let c1 = layoutFragment.rangeInElement.endLocation == selectionTextRange.location
                            result = result && c1
                        } else {
                            let c1 = contentRangeInElement.contains(selectionTextRange)
                            let c2 = contentRangeInElement.intersects(selectionTextRange)
                            let c3 = selectionTextRange.contains(contentRangeInElement)
                            let c4 = selectionTextRange.intersects(contentRangeInElement)
                            let c5 = contentRangeInElement.endLocation == selectionTextRange.location
                            result = result && (c1 || c2 || c3 || c4 || c5)
                        }
                        return partialResult && result
                    }
                }

                let isLineSelected = isLineSelected()

                var baselineYOffset: CGFloat = 0
                if let paragraphStyle = lineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle, !paragraphStyle.lineHeightMultiple.isAlmostZero() {
                    baselineYOffset = -(lineFragment.typographicBounds.height * (paragraphStyle.lineHeightMultiple - 1.0) / 2)
                }

                let lineNumber = startLineIndex + linesCount + 1
                let locationForFirstCharacter = lineFragment.locationForCharacter(at: 0)

                var lineFragmentFrame = CGRect(origin: CGPoint(x: 0, y: layoutFragment.layoutFragmentFrame.origin.y - contentOffset.y), size: layoutFragment.layoutFragmentFrame.size)

                lineFragmentFrame.origin.y += lineFragment.typographicBounds.origin.y
                if lineFragment.isExtraLineFragment {
                    lineFragmentFrame.size.height = lineFragment.typographicBounds.height
                } else if !lineFragment.isExtraLineFragment, let extraLineFragment = layoutFragment.textLineFragments.first(where: { $0.isExtraLineFragment }) {
                    lineFragmentFrame.size.height -= extraLineFragment.typographicBounds.height
                }

                var effectiveLineTextAttributes = lineTextAttributes
                if highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                    effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                }

                let numberView = STLineNumberView(
                    firstBaseline: locationForFirstCharacter.y + baselineYOffset,
                    attributes: effectiveLineTextAttributes,
                    number: lineNumber
                )

                numberView.insets = rulerView.rulerInsets

                if rulerView.highlightSelectedLine, isLineSelected, textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty, !textLayoutManager.insertionPointSelections.isEmpty {
                    numberView.backgroundColor = rulerView.selectedLineHighlightColor
                }

                numberView.frame = CGRect(
                    origin: lineFragmentFrame.origin,
                    size: CGSize(
                        width: max(lineFragmentFrame.intersection(rulerView.lineNumberViewContainer.frame).width, rulerView.lineNumberViewContainer.frame.width),
                        height: lineFragmentFrame.size.height
                    )
                )

                rulerView.lineNumberViewContainer.addSubview(numberView)
                linesCount += 1
            }

            return true
        }
    }
}
