//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md
//
//
//  STTextView
//

import UIKit
import STTextKitPlus
import STTextViewCommon

@objc open class STTextView: UIScrollView {

    /// Sent when the selection range of characters changes.
    public static let didChangeSelectionNotification = STTextLayoutManager.didChangeSelectionNotification

    /// The manager that lays out text for the text view's text container.
    @objc open private(set) var textLayoutManager: NSTextLayoutManager

    /// The text view's text storage object.
    @objc open private(set) var textContentManager: NSTextContentManager


    private let editableTextInteraction = UITextInteraction(for: .editable)
    private let nonEditableTextInteraction = UITextInteraction(for: .nonEditable)

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

    open override var canBecomeFirstResponder: Bool {
        !isFirstResponder && isEditable
    }

//    open override func becomeFirstResponder() -> Bool {
//        let isFirstResponder = self.isFirstResponder
//        let result = super.becomeFirstResponder()
//
//        if isFirstResponder == false && self.isFirstResponder == true {
//
//        }
//
//        return result
//    }

//    open override func resignFirstResponder() -> Bool {
//        // let isFirstResponder = self.isFirstResponder
//        let result = super.resignFirstResponder()
//
//        // if isFirstResponder == true && self.isFirstResponder == false {
//        //  removeInteraction(editableTextInteraction)
//        //  addInteraction(nonEditableTextInteraction)
//        // }
//
//        return result
//    }

    public override init(frame: CGRect) {
        textContentManager = STTextContentStorage()
        textLayoutManager = STTextLayoutManager()

        isSelectable = true
        isEditable = true


        super.init(frame: frame)

        editableTextInteraction.textInput = self
        editableTextInteraction.delegate = self

        nonEditableTextInteraction.textInput = self
        nonEditableTextInteraction.delegate = self

        // isUserInteractionEnabled = true

        updateEditableInteraction()
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

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        //becomeFirstResponder()
    }
}
