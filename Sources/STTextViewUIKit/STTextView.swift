//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//      |---contentView
//              |---STLineHighlightView
//              |---STTextLayoutFragmentView
//      |---gutterView

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
    @objc dynamic open var textLayoutManager: NSTextLayoutManager {
        willSet {
            textContentManager.primaryTextLayoutManager = nil
            textContentManager.removeTextLayoutManager(newValue)
        }
        didSet {
            textContentManager.addTextLayoutManager(textLayoutManager)
            textContentManager.primaryTextLayoutManager = textLayoutManager
            setupTextLayoutManager(textLayoutManager)
            self.text = text
        }
    }

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

    /// Extra padding below the text content for "scroll past end" behavior.
    ///
    /// When set to a value greater than 0:
    /// - The padding is added to the content height in `sizeToFit()`
    ///
    /// Default is `0` (no extra padding).
    @MainActor
    open var bottomPadding: CGFloat = 0

    /// Custom annotation decorations to render on text (underlines, backgrounds).
    ///
    /// Set this property to display decorations at specific character ranges.
    /// Decorations are rendered efficiently, only drawing for visible text.
    /// Setting this property triggers a redisplay of affected fragments.
    @MainActor
    open var annotationDecorations: [STAnnotationDecoration] = [] {
        didSet {
            // Sort by range location for efficient fragment intersection
            if !annotationDecorations.isEmpty {
                annotationDecorations.sort { $0.range.location < $1.range.location }
            }
            // Redisplay affected fragments
            setNeedsDisplay()
            contentView.setNeedsDisplay()
            for subview in contentView.subviews {
                subview.setNeedsDisplay()
            }
        }
    }

    /// Enable to show line numbers in the gutter.
    @Invalidating(.layout)
    public var showsLineNumbers: Bool = false {
        didSet {
            isGutterVisible = showsLineNumbers
        }
    }

    @Invalidating(.layout)
    public var showsInvisibleCharacters: Bool = false {
        didSet {
            textLayoutManager.invalidateLayout(for: textLayoutManager.textViewportLayoutController.viewportRange ?? textLayoutManager.documentRange)
        }
    }

    /// The highlight color of the selected line.
    ///
    /// Note: Needs ``highlightSelectedLine`` to be set to `true`
    @Invalidating(.display)
    @objc dynamic open var selectedLineHighlightColor: UIColor = UIColor.tintColor.withAlphaComponent(0.15)

    /// The font of the text. Default font.
    ///
    /// Assigning a new value to this property causes the new font to be applied to the entire contents of the text view.
    /// If you want to apply the font to only a portion of the text, you must create a new attributed string with the desired style information and assign it
    @objc public var font: UIFont {
        get {
            _defaultTypingAttributes[.font] as! UIFont
        }

        set {
            _defaultTypingAttributes[.font] = newValue

            // apply to the document
            if !textLayoutManager.documentRange.isEmpty {
                addAttributes([.font: newValue], range: textLayoutManager.documentRange)
            }

            updateTypingAttributes()
        }
    }

    /// The text color of the text view.
    ///
    /// Default text color.
    @objc public var textColor: UIColor {
        get {
            _defaultTypingAttributes[.foregroundColor] as! UIColor
        }

        set {
            _defaultTypingAttributes[.foregroundColor] = newValue

            // apply to the document
            if !textLayoutManager.documentRange.isEmpty {
                addAttributes([.foregroundColor: newValue], range: textLayoutManager.documentRange)
            }

            updateTypingAttributes()
        }
    }

    /// Gutter view
    public var gutterView: STGutterView?

    /// Installed plugins. events value is available after plugin is setup
    internal var plugins: [Plugin] = []

    /// Content view. Layout fragments content.
    internal let contentView: STContentView

    /// Content frame. Layout fragments content frame.
    public var contentFrame: CGRect {
        contentView.frame
    }

    /// Line highlight view.
    internal let lineHighlightView: STLineHighlightView

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

    /// A Boolean value that indicates whether the receiver allows undo.
    ///
    /// `true` if the receiver allows undo, otherwise `false`. Default `true`.
    @objc dynamic public var allowsUndo: Bool
    internal var _undoManager: UndoManager?

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
                setSelectedTextRange(NSTextRange(location: prevLocation), updateLayout: true)
            } else {
                // or try to set at the begining of the document
                setSelectedTextRange(NSTextRange(location: textContentManager.documentRange.location), updateLayout: true)
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
                setSelectedTextRange(NSTextRange(location: prevLocation), updateLayout: true)
            } else {
                // or try to set at the begining of the document
                setSelectedTextRange(NSTextRange(location: textContentManager.documentRange.location), updateLayout: true)
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
            if isEditable != oldValue && !isEditable {
                resignFirstResponder()
                updateEditableInteraction()
            }
        }
    }

    /// A Boolean value that controls whether the text views allows the user to select text.
    // @Invalidating(.insertionPoint, .cursorRects)
    @objc dynamic open var isSelectable: Bool {
        didSet {
            if isSelectable != oldValue, !isSelectable {
                resignFirstResponder()
                updateEditableInteraction()
            }
        }

    }

    /// The receiver’s default paragraph style.
    @objc public var defaultParagraphStyle: NSParagraphStyle {
        set {
            _defaultTypingAttributes[.paragraphStyle] = newValue
        }
        get {
            _defaultTypingAttributes[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
        }
    }

    /// Default typing attributes used in place of missing attributes of font, color and paragraph
    internal var _defaultTypingAttributes: [NSAttributedString.Key: Any] = [
        .paragraphStyle: NSParagraphStyle.default,
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.label
    ]

    /// The attributes to apply to new text that the user enters.
    ///
    /// This dictionary contains the attribute keys (and corresponding values) to apply to newly typed text.
    /// When the text view’s selection changes, the contents of the dictionary are reset automatically.
    @objc public internal(set) var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            _typingAttributes.merging(_defaultTypingAttributes) { (current, _) in current }
        }

        set {
            _typingAttributes = newValue.filter {
                _allowedTypingAttributes.contains($0.key)
            }
            setNeedsDisplay()
        }
    }

    private var _typingAttributes: [NSAttributedString.Key: Any]
    private var _allowedTypingAttributes: [NSAttributedString.Key] = [
        .paragraphStyle,
        .font,
        .foregroundColor,
        .baselineOffset,
        .kern,
        .ligature,
        .shadow,
        .strikethroughColor,
        .strikethroughStyle,
        .languageIdentifier,
        .tracking,
        .writingDirection,
        .textEffect,
        .backgroundColor,
        .baselineOffset,
        .underlineColor,
        .underlineStyle
    ]

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
        if textLayoutManager.documentRange.isEmpty {
            return _defaultTypingAttributes
        }

        var typingAttrs: [NSAttributedString.Key: Any] = [:]
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
                typingAttrs = attributedTextElement.attributedString.attributes(at: offset + offsetDiff, effectiveRange: nil)
            }

            return false
        }

        // fill in with missing typing attributes if needed
        return typingAttrs.merging(_defaultTypingAttributes, uniquingKeysWith: { current, _ in current})
    }

    // line height based on current typing font and current typing paragraph
    internal var typingLineHeight: CGFloat {
        let font = typingAttributes[.font] as? UIFont ?? _defaultTypingAttributes[.font] as! UIFont
        let paragraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? _defaultTypingAttributes[.paragraphStyle] as! NSParagraphStyle
        return calculateDefaultLineHeight(for: font) * paragraphStyle.stLineHeightMultiple
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

        contentView = STContentView()

        lineHighlightView = STLineHighlightView()
        lineHighlightView.isHidden = true

        allowsUndo = true
        _undoManager = CoalescingUndoManager()

        _typingAttributes = [:]

        super.init(frame: frame)

        contentView.clipsToBounds = clipsToBounds
        lineHighlightView.clipsToBounds = clipsToBounds

        addSubview(contentView)
        contentView.addSubview(lineHighlightView)

        editableTextInteraction.textInput = self
        editableTextInteraction.delegate = self

        nonEditableTextInteraction.textInput = self
        nonEditableTextInteraction.delegate = self

        updateEditableInteraction()
        isGutterVisible = showsLineNumbers

        setupTextLayoutManager(textLayoutManager)
        setSelectedTextRange(NSTextRange(location: textLayoutManager.documentRange.location), updateLayout: false)
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var didChangeSelectionNotificationObserver: NSObjectProtocol?
    private func setupTextLayoutManager(_ textLayoutManager: NSTextLayoutManager) {
        textLayoutManager.delegate = self
        textLayoutManager.textViewportLayoutController.delegate = self

        // Forward didChangeSelectionNotification from STTextLayoutManager
        if let didChangeSelectionNotificationObserver {
            NotificationCenter.default.removeObserver(didChangeSelectionNotificationObserver)
        }
        didChangeSelectionNotificationObserver = NotificationCenter.default.addObserver(forName: STTextLayoutManager.didChangeSelectionNotification, object: textLayoutManager, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            let textViewNotification = Notification(name: Self.didChangeSelectionNotification, object: self, userInfo: notification.userInfo)

            NotificationCenter.default.post(textViewNotification)
            self.delegateProxy.textViewDidChangeSelection(textViewNotification)
            // NSAccessibility.post(element: self, notification: .selectedTextChanged)
        }
    }

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view
    @objc public func toggleRuler(_ sender: Any?) {
        isGutterVisible.toggle()
    }

    /// The current selection range of the text view.
    ///
    /// If the length of the selection range is 0, indicating that the selection is actually an insertion point
    public var textSelection: NSRange {
        set {
            setSelectedRange(newValue)
        }

        get {
            if let selectionTextRange = textLayoutManager.textSelections.last?.textRanges.last {
                return NSRange(selectionTextRange, in: textContentManager)
            }

            return .notFound
        }
    }

    internal func setSelectedTextRange(_ textRange: NSTextRange, updateLayout: Bool) {
        guard isSelectable, textRange.endLocation <= textLayoutManager.documentRange.endLocation else {
            return
        }

        self.selectedTextRange = textRange.uiTextRange

        if updateLayout {
            setNeedsLayout()
        }
    }

    internal func setSelectedRange(_ range: NSRange) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }
        setSelectedTextRange(textRange, updateLayout: true)
    }

    /// Add attribute.
    open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        addAttributes(attrs, range: range, updateLayout: true)
    }

    /// Add attribute.
    internal func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        addAttributes(attrs, range: textRange, updateLayout: updateLayout)
    }

    /// Add attribute.
    internal func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.addAttributes(attrs, range: NSRange(range, in: textContentManager))
        }

        if updateLayout {
            setNeedsLayout()
        }
    }

    /// Set attributes.
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        setAttributes(attrs, range: range, updateLayout: true)
    }

    /// Set attributes.
    internal func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange, updateLayout: Bool) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        setAttributes(attrs, range: textRange, updateLayout: updateLayout)
    }

    /// Set attributes.
    internal func setAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.setAttributes(attrs, range: NSRange(range, in: textContentManager))
        }


        if updateLayout {
            setNeedsLayout()
        }
    }

    /// Set attributes.
    open func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange) {
        removeAttribute(attribute, range: range, updateLayout: true)
    }

    /// Set attributes.
    internal func removeAttribute(_ attribute: NSAttributedString.Key, range: NSRange, updateLayout: Bool) {
        guard let textRange = NSTextRange(range, in: textContentManager) else {
            preconditionFailure("Invalid range \(range)")
        }

        removeAttribute(attribute, range: textRange, updateLayout: updateLayout)
    }

    /// Set attributes.
    internal func removeAttribute(_ attribute: NSAttributedString.Key, range: NSTextRange, updateLayout: Bool = true) {

        textContentManager.performEditingTransaction {
            (textContentManager as? NSTextContentStorage)?.textStorage?.removeAttribute(attribute, range: NSRange(range, in: textContentManager))
        }

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

        func setupNoInteraction() {
            removeInteraction(editableTextInteraction)
            removeInteraction(nonEditableTextInteraction)
        }

        if isEditable {
            setupEditableInteraction()
        } else if isSelectable {
            setupNonEditableInteraction()
        } else {
            setupNoInteraction()
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
        let gutterWidth = gutterView?.frame.width ?? 0
        let verticalScrollInset = contentInset.top + contentInset.bottom
        let visibleRectSize = self.bounds.size
        
        // For wrapped text, we need to configure container size BEFORE layout calculations
        if !isHorizontallyResizable {
            // Pre-configure text container width for wrapping mode
            let proposedContentWidth = visibleRectSize.width - gutterWidth
            if !textContainer.size.width.isAlmostEqual(to: proposedContentWidth) {
                var containerSize = textContainer.size
                containerSize.width = proposedContentWidth
                textContainer.size = containerSize
                logger.debug("Pre-configured textContainer.size.width \(proposedContentWidth) for wrapping \(#function)")
            }
        }
        
        // Now perform layout with correct container size
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

        // Estimated text container size to layout document
        textLayoutManager.ensureLayout(for: NSTextRange(location: textLayoutManager.documentRange.endLocation))

        super.sizeToFit()

        let usageBoundsForTextContainer = textLayoutManager.usageBoundsForTextContainer

        var frameSize: CGSize
        if isHorizontallyResizable {
            // no-wrapping
            frameSize = CGSize(
                width: max(usageBoundsForTextContainer.size.width + gutterWidth + textContainer.lineFragmentPadding, visibleRectSize.width),
                height: max(usageBoundsForTextContainer.size.height, visibleRectSize.height - verticalScrollInset)
            )
        } else {
            // wrapping
            frameSize = CGSize(
                width: visibleRectSize.width - gutterWidth,
                height: max(usageBoundsForTextContainer.size.height, visibleRectSize.height - verticalScrollInset)
            )
        }

        // Add bottom padding for "scroll past end" behavior
        if bottomPadding > 0 {
            frameSize.height += bottomPadding
        }

        if !frame.size.isAlmostEqual(to: frameSize) {
            logger.debug("contentView.frame.size (\(frameSize.width), \(frameSize.height)) \(#function)")
            self.contentView.frame.origin.x = gutterWidth
            self.contentView.frame.size = frameSize
            self.contentSize = frameSize
        }

        // Final container size configuration (handles vertical resizing and any adjustments)
        _configureTextContainerSize()
    }

    // Update textContainer width to match textview width if track textview width
    // widthTracksTextView = true
    private func _configureTextContainerSize() {
        var proposedSize = textContainer.size
        if !isHorizontallyResizable {
            proposedSize.width = contentSize.width // - _textContainerInset.width * 2
        }

        if !isVerticallyResizable {
            proposedSize.height = contentSize.height // - _textContainerInset.height * 2
        }

        if !textContainer.size.isAlmostEqual(to: proposedSize)  {
            textContainer.size = proposedSize
            logger.debug("textContainer.size (\(self.textContainer.size.width), \(self.textContainer.size.width)) \(#function)")
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
                updateTypingAttributes()
            }
        case let attributedString as NSAttributedString:
            if shouldChangeText(in: textRanges, replacementString: attributedString.string) {
                replaceCharacters(in: textRanges, with: attributedString, allowsTypingCoalescing: true)
                updateTypingAttributes()
            }
        default:
            assertionFailure()
        }

    }

    open func replaceCharacters(in range: NSTextRange, with string: String) {
        replaceCharacters(in: range, with: string, useTypingAttributes: true, allowsTypingCoalescing: false)
    }

    open func replaceCharacters(in range: NSRange, with string: String) {
        guard let textContentManager = textLayoutManager.textContentManager,
              let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }
        replaceCharacters(in: textRange, with: string)
    }

    open func replaceCharacters(in range: NSRange, with string: NSAttributedString) {
        guard let textContentManager = textLayoutManager.textContentManager,
              let textRange = NSTextRange(range, in: textContentManager) else {
            return
        }
        replaceCharacters(in: textRange, with: string, allowsTypingCoalescing: false)
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
            replaceCharacters(in: textRange, with: replacementString, allowsTypingCoalescing: allowsTypingCoalescing)
        }
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: String, useTypingAttributes: Bool, allowsTypingCoalescing: Bool) {
        self.replaceCharacters(
            in: textRange,
            with: NSAttributedString(string: replacementString, attributes: useTypingAttributes ? typingAttributes : [:]),
            allowsTypingCoalescing: allowsTypingCoalescing
        )
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        let previousStringInRange = (textContentManager as? NSTextContentStorage)!.attributedString!.attributedSubstring(from: NSRange(textRange, in: textContentManager))

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

        guard allowsUndo, let undoManager = undoManager, undoManager.isUndoRegistrationEnabled else { return }

        // Reach to NSTextStorage because NSTextContentStorage range extraction is cumbersome.
        // A range that is as long as replacement string, so when undo it undo
        let undoRange = NSTextRange(
            location: textRange.location,
            end: textContentManager.location(textRange.location, offsetBy: replacementString.length)
        ) ?? textRange

        if let coalescingUndoManager = undoManager as? CoalescingUndoManager, !undoManager.isUndoing, !undoManager.isRedoing {
            if allowsTypingCoalescing /*&& processingKeyEvent*/ {
               coalescingUndoManager.checkCoalescing(range: undoRange)
           } else {
               coalescingUndoManager.endCoalescing()
           }
        }
        
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: self) { textView in
            // Regular undo action
            textView.replaceCharacters(
                in: undoRange,
                with: previousStringInRange,
                allowsTypingCoalescing: false
            )
            textView.setSelectedTextRange(textRange, updateLayout: true)
        }
        undoManager.endUndoGrouping()
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

    /// Informs the receiver that it should begin coalescing successive typing operations in a new undo grouping
    public func breakUndoCoalescing() {
        (undoManager as? CoalescingUndoManager)?.endCoalescing()
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copy(_:)):
            return selectedTextRange?.isEmpty == false
        case #selector(cut(_:)):
            return isEditable && selectedTextRange?.isEmpty == false
        case #selector(paste(_:)):
            return isEditable && UIPasteboard.general.hasStrings
        case #selector(selectAll(_:)):
            return isSelectable
        case #selector(select(_:)):
            return isSelectable
        case #selector(replace(_:)):
            return isEditable
        case #selector(delete(_:)):
            return isEditable && selectedTextRange?.isEmpty == false
        default:
            return super.canPerformAction(action, withSender: sender)
        }
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

    // Update selected line highlight layer
    internal func updateSelectedLineHighlight() {
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
                        x: 0,
                        y: selectionFrame.origin.y
                    ),
                    size: CGSize(
                        width: contentView.frame.width,
                        height: typingLineHeight
                    )
                ).pixelAligned
            }
        } else if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
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
                for textLineFragment in layoutFragment.textLineFragments {

                    let isLineSelected = STGutterCalculations.isLineSelected(
                        textLineFragment: textLineFragment,
                        layoutFragment: layoutFragment,
                        contentRangeInElement: contentRangeInElement,
                        textLayoutManager: textLayoutManager
                    )

                    if isLineSelected {
                        let lineSelectionRectangle: CGRect

                        if !textLineFragment.isExtraLineFragment {
                            var lineFragmentFrame = layoutFragment.layoutFragmentFrame
                            lineFragmentFrame.size.height = textLineFragment.typographicBounds.height

                            lineSelectionRectangle = CGRect(
                                origin: CGPoint(
                                    x: 0,
                                    y: lineFragmentFrame.origin.y + textLineFragment.typographicBounds.minY
                                ),
                                size: CGSize(
                                    width: contentView.bounds.size.width,
                                    height: lineFragmentFrame.height
                                )
                            )
                        } else {
                            // Workaround for FB15131180
                            let prevTextLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                            var lineFragmentFrame = layoutFragment.layoutFragmentFrame
                            lineFragmentFrame.size.height = prevTextLineFragment.typographicBounds.height

                            lineSelectionRectangle = CGRect(
                                origin: CGPoint(
                                    x: 0,
                                    y: lineFragmentFrame.origin.y + prevTextLineFragment.typographicBounds.maxY
                                ),
                                size: CGSize(
                                    width: contentView.bounds.width,
                                    height: lineFragmentFrame.height
                                )
                            )
                        }

                        if let rect = combinedFragmentsRect {
                            combinedFragmentsRect = rect.union(lineSelectionRectangle)
                        } else {
                            combinedFragmentsRect = lineSelectionRectangle
                        }
                    }
                }
                return true
            }

            if let combinedFragmentsRect {
                lineHighlightView.frame = combinedFragmentsRect.pixelAligned
            }
        }
    }
    
    open func addPlugin(_ instance: any STPlugin) {
        let plugin = Plugin(instance: instance)
        plugins.append(plugin)
        setupPlugins()
    }

    private func setupPlugins() {
        for (offset, plugin) in plugins.enumerated() where plugin.events == nil {
            // set events handler
            var plugin = plugin
            plugin.events = setUp(instance: plugin.instance)
            plugins[offset] = plugin
        }
    }

    @MainActor
    private func setUp(instance: some STPlugin) -> STPluginEvents {
        // unwrap any STPluginProtocol
        let events = STPluginEvents()
        instance.setUp(
            context: STPluginContext(
                coordinator: instance.makeCoordinator(context: .init(textView: self)),
                textView: self,
                events: events
            )
        )
        return events
    }
}
