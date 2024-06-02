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

    public var autocorrectionType: UITextAutocorrectionType = .default
    public var autocapitalizationType: UITextAutocapitalizationType = .sentences
    public var smartQuotesType: UITextSmartQuotesType = .default
    public var smartDashesType: UITextSmartDashesType = .default
    public var smartInsertDeleteType: UITextSmartInsertDeleteType = .default
    public var spellCheckingType: UITextSpellCheckingType = .default
    public var keyboardType: UIKeyboardType = .default
    public var keyboardAppearance: UIKeyboardAppearance = .default
    public var returnKeyType: UIReturnKeyType = .default

    /// The manager that lays out text for the text view's text container.
    @objc open private(set) var textLayoutManager: NSTextLayoutManager

    /// The text view's text storage object.
    @objc open private(set) var textContentManager: NSTextContentManager

    /// The text view's text container
    public var textContainer: NSTextContainer {
        textLayoutManager.textContainer!
    }

    /// Content view. Layout fragments content.
    internal let contentView: ContentView

    internal var fragmentViewMap: NSMapTable<NSTextLayoutFragment, STTextLayoutFragmentView>

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
            if let prevLocation = prevLocation {
                setSelectedTextRange(NSTextRange(location: prevLocation))
            }
        }

        get {
            textContentManager.attributedString(in: nil)?.string
        }
    }

    /// The styled text that the text view displays.
    // @NSCopying public var attributedText: NSAttributedString?

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

//        _selectedTextRange = STTextLocationRange(textRange: NSTextRange(location: textLayoutManager.documentRange.location))

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

        // TODO: updateTypingAttributes(at: textRange.location)

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
            with: NSAttributedString(string: replacementString/*, attributes: useTypingAttributes ? typingAttributes : [:]*/),
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
            with: NSAttributedString(string: replacementString/*, attributes: useTypingAttributes ? typingAttributes : [:]*/),
            allowsTypingCoalescing: allowsTypingCoalescing
        )
    }

    internal func replaceCharacters(in textRange: NSTextRange, with replacementString: NSAttributedString, allowsTypingCoalescing: Bool) {
        inputDelegate?.textWillChange(self)
        //delegateProxy.textView(self, willChangeTextIn: textRange, replacementString: replacementString.string)

        textContentManager.performEditingTransaction {
            textContentManager.replaceContents(
                in: textRange,
                with: [NSTextParagraph(attributedString: replacementString)]
            )
        }

        //delegateProxy.textView(self, didChangeTextIn: textRange, replacementString: replacementString.string)
        inputDelegate?.textDidChange(self)
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
