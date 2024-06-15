//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit

extension STTextView {

    /// Updates the insertion point’s location and optionally restarts the blinking cursor timer.
    public func updateInsertionPointStateAndRestartTimer() {
        // Hide insertion point layers
        if shouldDrawInsertionPoint {
            let insertionPointsRanges = textLayoutManager.insertionPointSelections.flatMap(\.textRanges).filter(\.isEmpty)
            guard !insertionPointsRanges.isEmpty else {
                return
            }

            let textSelectionFrames = insertionPointsRanges.compactMap { textRange -> CGRect? in

                guard let textSegmentFrame = textLayoutManager.textSegmentFrame(in: textRange, type: .selection, options: .rangeNotRequired) else {
                    return nil
                }
                
                let selectionFrame = textSegmentFrame.intersection(frame)

                // because `textLayoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresExtraLineFragment, .ensuresLayout, .estimatesSize])`
                // returns unexpected value for extra line fragment height (return 14) that is not correct in the context,
                // therefore for empty override height with value manually calculated from font + paragraph style
                if textRange == textLayoutManager.documentRange, textRange.isEmpty {
                    return CGRect(origin: selectionFrame.origin, size: CGSize(width: selectionFrame.width, height: typingLineHeight)).pixelAligned
                }

                return selectionFrame
            }

            removeInsertionPointView()

            for selectionFrame in textSelectionFrames where !selectionFrame.isNull && !selectionFrame.isInfinite {
                let insertionViewFrame = CGRect(origin: selectionFrame.origin, size: CGSize(width: max(2, selectionFrame.width), height: selectionFrame.height))

                var textInsertionIndicator: any STInsertionPointIndicatorProtocol
                if let customTextInsertionIndicator = self.delegateProxy.textViewInsertionPointView(self, frame: CGRect(origin: .zero, size: insertionViewFrame.size)) {
                    textInsertionIndicator = customTextInsertionIndicator
                } else {
                    if #available(macOS 14, *) {
                        textInsertionIndicator = STTextInsertionIndicatorNew(frame: CGRect(origin: .zero, size: insertionViewFrame.size))
                    } else {
                        textInsertionIndicator = STTextInsertionIndicatorOld(frame: CGRect(origin: .zero, size: insertionViewFrame.size))
                    }
                }

                let insertionView = STInsertionPointView(frame: insertionViewFrame, textInsertionIndicator: textInsertionIndicator)
                insertionView.clipsToBounds = false
                insertionView.insertionPointColor = insertionPointColor

                if isFirstResponder {
                    insertionView.blinkStart()
                } else {
                    insertionView.blinkStop()
                }

                contentView.addSubview(insertionView)
            }
        } else if !shouldDrawInsertionPoint {
            removeInsertionPointView()
        }
    }

    func removeInsertionPointView() {
        contentView.subviews.removeAll { view in
            type(of: view) == STInsertionPointView.self
        }
    }

}

@available(macOS 14.0, *)
private class STTextInsertionIndicatorNew: NSTextInsertionIndicator, STInsertionPointIndicatorProtocol {

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var insertionPointColor: NSColor {
        get {
            color
        }

        set {
            color = newValue
        }
    }

    func blinkStart() {
        displayMode = .automatic
    }

    func blinkStop() {
        displayMode = .hidden
    }

    open override var isFlipped: Bool {
        true
    }
}

private class STTextInsertionIndicatorOld: NSView, STInsertionPointIndicatorProtocol {
    private var timer: Timer?

    var insertionPointColor: NSColor = .defaultTextInsertionPoint {
        didSet {
            layer?.backgroundColor = insertionPointColor.cgColor
        }
    }

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = insertionPointColor.withAlphaComponent(0.9).cgColor
        layer?.cornerRadius = 1
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func blinkStart() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            self?.isHidden.toggle()
        }
    }

    func blinkStop() {
        isHidden = false
        timer?.invalidate()
        timer = nil
    }

    open override var isFlipped: Bool {
        true
    }
}

