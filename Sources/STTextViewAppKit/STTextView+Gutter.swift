//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import AppKit
import STTextKitPlus
import CoreTextSwift
import STTextViewCommon

extension STTextView {

    /// This action method shows or hides the ruler, if the receiver is enclosed in a scroll view.
    @objc public func toggleRuler(_ sender: Any?) {
        isGutterVisible.toggle()
    }

    /// A Boolean value that controls whether the scroll view enclosing text views sharing the receiver’s layout manager displays the ruler.
    var isGutterVisible: Bool {
        set {
            if gutterView == nil, newValue == true {
                let gutterView = STGutterView()
                // estimate max gutter width
                gutterView.frame.origin = .zero
                gutterView.frame.size.width = max(gutterView.minimumThickness, CGFloat(textContentManager.length) / (1024 * 100))
                gutterView.frame.size.height = contentView.bounds.height
                gutterView.textColor = textColor.withAlphaComponent(0.45)
                gutterView.selectedLineTextColor = textColor
                gutterView.highlightSelectedLine = highlightSelectedLine
                gutterView.selectedLineHighlightColor = selectedLineHighlightColor
                gutterView.backgroundColor = backgroundColor
                if let enclosingScrollView {
                    enclosingScrollView.addFloatingSubview(gutterView, for: .horizontal)
                } else {
                    self.addSubview(gutterView)
                }
                self.gutterView = gutterView
                needsLayout = true
                layoutGutter()
            } else if newValue == false, let gutterView {
                gutterView.removeFromSuperview()
                self.gutterView = nil
                needsLayout = true
                layoutGutter()
            }
        }
        get {
            gutterView != nil
        }
    }

    func layoutGutter() {
        // Layout built-in gutter (line numbers + markers)
        if let gutterView, textLayoutManager.textViewportLayoutController.viewportRange != nil {
            gutterView.frame.size.height = contentView.bounds.height

            layoutGutterLineNumbers()
            layoutGutterMarkers()
        }

        // Layout custom gutter line views (independent of built-in gutter)
        layoutCustomGutterLineViews()
    }


    private func layoutGutterLineNumbers() {
        guard let gutterView else {
            return
        }

        gutterView.containerView.subviews.compactMap {
            $0 as? STGutterLineNumberCell
        }.forEach {
            $0.removeFromSuperviewWithoutNeedingDisplay()
        }

        let lineTextAttributes: [NSAttributedString.Key: Any] = [
            .font: gutterView.font,
            .foregroundColor: gutterView.textColor
        ]

        let selectedLineTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: (gutterView.selectedLineTextColor ?? gutterView.textColor).cgColor
        ]

        // if empty document
        if textLayoutManager.documentRange.isEmpty {
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                let lineNumber = 1

                // Use typingAttributes to calculate baseline position for empty document.
                // The cell is sized for typingLineHeight, so baseline calculation should use typing font metrics
                // to match where text baseline would be. Line number is still drawn with gutter font.
                let ctNumberLine = CTLineCreateWithAttributedString(NSAttributedString(string: "\(lineNumber)", attributes: typingAttributes))
                let baselineParagraphStyle = typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? defaultParagraphStyle
                let baselineOffset = -(ctNumberLine.typographicHeight() * (baselineParagraphStyle.stLineHeightMultiple - 1.0) / 2)

                var effectiveLineTextAttributes = lineTextAttributes
                if gutterView.highlightSelectedLine /* , isLineSelected */, !selectedLineTextAttributes.isEmpty {
                    effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                }

                let numberCell = STGutterLineNumberCell(
                    firstBaseline: ctNumberLine.typographicBounds().ascent - baselineOffset,
                    attributes: effectiveLineTextAttributes,
                    number: lineNumber
                )

                numberCell.insets = gutterView.insets

                if gutterView.highlightSelectedLine, textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty, !textLayoutManager.insertionPointSelections.isEmpty {
                    numberCell.layer?.backgroundColor = gutterView.selectedLineHighlightColor.cgColor
                }

                // For empty documents, ignore bounce scrolling by treating scroll offset as 0
                // Empty document fits in viewport, so any scroll is just bounce effect
                numberCell.frame = CGRect(
                    origin: CGPoint(
                        x: 0,
                        y: selectionFrame.origin.y
                    ),
                    size: CGSize(
                        width: gutterView.containerView.frame.width,
                        height: typingLineHeight
                    )
                ).pixelAligned

                gutterView.containerView.addSubview(numberCell)
            }
        } else if let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange {
            // Get visible fragment views from the map and sort by document order
            let visibleFragmentViews = STGutterCalculations.visibleFragmentViewsInViewport(
                fragmentViewMap: fragmentViewMap,
                viewportRange: viewportRange
            )

            guard !visibleFragmentViews.isEmpty else {
                return
            }

            // Calculate how many lines exist before the viewport
            let textElementsBeforeViewport = textContentManager.textElements(
                for: NSTextRange(
                    location: textLayoutManager.documentRange.location,
                    end: viewportRange.location
                )!
            )

            var requiredWidthFitText = gutterView.minimumThickness
            let startLineIndex = textElementsBeforeViewport.count
            var linesCount = 0

            for (layoutFragment, fragmentView) in visibleFragmentViews {
                let contentRangeInElement = (layoutFragment.textElement as? NSTextParagraph)?.paragraphContentRange ?? layoutFragment.rangeInElement

                // Only show line numbers for the first line fragment or extra line fragments
                for textLineFragment in layoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == textLineFragment) {
                    let lineNumber = startLineIndex + linesCount + 1

                    // Determine if this line is selected
                    let isLineSelected = STGutterCalculations.isLineSelected(
                        textLineFragment: textLineFragment,
                        layoutFragment: layoutFragment,
                        contentRangeInElement: contentRangeInElement,
                        textLayoutManager: textLayoutManager
                    )

                    // Calculate positioning metrics
                    // Get the actual fragment view frame for pixel-perfect alignment
                    let (baselineYOffset, locationForFirstCharacter, cellFrame) = STGutterCalculations.calculateLineNumberMetrics(
                        for: textLineFragment,
                        in: layoutFragment,
                        fragmentViewFrame: fragmentView.frame
                    )

                    // Prepare text attributes
                    var effectiveLineTextAttributes = lineTextAttributes
                    if gutterView.highlightSelectedLine, isLineSelected, !selectedLineTextAttributes.isEmpty {
                        effectiveLineTextAttributes.merge(selectedLineTextAttributes, uniquingKeysWith: { (_, new) in new })
                    }
                    if let paragraphStyle = textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                        effectiveLineTextAttributes[.paragraphStyle] = paragraphStyle
                    }

                    // Create and configure line number cell
                    let numberCell = STGutterLineNumberCell(
                        firstBaseline: locationForFirstCharacter.y + baselineYOffset,
                        attributes: effectiveLineTextAttributes,
                        number: lineNumber
                    )
                    numberCell.insets = gutterView.insets

                    // Apply selection highlight if needed
                    if gutterView.highlightSelectedLine, isLineSelected,
                       textLayoutManager.textSelectionsRanges(.withoutInsertionPoints).isEmpty,
                       !textLayoutManager.insertionPointSelections.isEmpty {
                        numberCell.layer?.backgroundColor = gutterView.selectedLineHighlightColor.cgColor
                    }

                    // Position the cell
                    numberCell.frame = CGRect(
                        origin: CGPoint(
                            x: 0,
                            y: cellFrame.origin.y
                        ),
                        size: CGSize(
                            width: max(cellFrame.intersection(gutterView.containerView.frame).width, gutterView.containerView.frame.width),
                            height: cellFrame.size.height
                        )
                    ).pixelAligned

                    gutterView.containerView.addSubview(numberCell)
                    requiredWidthFitText = max(requiredWidthFitText, numberCell.intrinsicContentSize.width)
                    linesCount += 1
                }
            }

            // adjust ruleThickness to fit the text based on last numberView
            if textLayoutManager.textViewportLayoutController.viewportRange != nil {
                let newGutterWidth = max(requiredWidthFitText, gutterView.minimumThickness)
                if !newGutterWidth.isAlmostEqual(to: gutterView.frame.size.width, tolerance: .ulpOfOne), newGutterWidth > gutterView.frame.size.width {
                    gutterView.frame.size.width = newGutterWidth
                }
            }
        }
    }

    private func layoutGutterMarkers() {
        guard let gutterView else {
            return
        }

        gutterView.layoutMarkers()
    }

    // MARK: - Custom Gutter Line Views

    /// Identifier prefix for custom gutter line views.
    private static let gutterLineViewIDPrefix = "stgutter-line-"

    /// Identifier for the trailing separator view inside the custom gutter container.
    private static let gutterSeparatorID = NSUserInterfaceItemIdentifier("stgutter-separator")

    /// Positions custom gutter line views provided by ``gutterLineViewDataSource``.
    /// Creates the container view lazily as a floating subview, then enumerates
    /// visible lines to create and position one NSView per paragraph.
    ///
    /// Views are recreated on each layout pass to pick up fresh state.
    private func layoutCustomGutterLineViews() {
        guard let dataSource = gutterLineViewDataSource, customGutterWidth > 0 else {
            return
        }

        // Lazy container setup — added as floating subview so it stays
        // at a fixed horizontal position while scrolling vertically with content.
        if customGutterContainerView == nil {
            let container = STCustomGutterContainerView()
            container.frame = NSRect(x: 0, y: 0, width: customGutterWidth, height: contentView.bounds.height)
            if let enclosingScrollView {
                // Clip floating subviews at the scroll view bounds so the gutter
                // doesn't render outside the visible editor area.
                enclosingScrollView.clipsToBounds = true
                enclosingScrollView.addFloatingSubview(container, for: .horizontal)
            } else {
                addSubview(container)
            }
            customGutterContainerView = container
        }

        guard let container = customGutterContainerView else { return }

        // Update container dimensions and background
        container.frame.size.width = customGutterWidth
        container.frame.size.height = contentView.bounds.height
        container.layer?.backgroundColor = customGutterBackgroundColor?.cgColor

        // Track which line numbers are currently visible so we can prune stale views
        var visibleIDs = Set<NSUserInterfaceItemIdentifier>()

        // Empty document — show a single view for line 1
        if textLayoutManager.documentRange.isEmpty {
            if let selectionFrame = textLayoutManager.textSegmentFrame(at: textLayoutManager.documentRange.location, type: .standard) {
                let lineID = Self.gutterLineViewID(for: 1)
                visibleIDs.insert(lineID)

                let lineView = lineViewForID(lineID, in: container, dataSource: dataSource, lineNumber: 1, lineContent: "")
                lineView.frame = CGRect(
                    origin: CGPoint(x: 0, y: selectionFrame.origin.y),
                    size: CGSize(width: customGutterWidth, height: typingLineHeight)
                ).pixelAligned
            }
            pruneStaleLineViews(in: container, keeping: visibleIDs)
            addCustomGutterSeparator(to: container)
            return
        }

        guard let viewportRange = textLayoutManager.textViewportLayoutController.viewportRange else {
            return
        }

        let visibleFragmentViews = STGutterCalculations.visibleFragmentViewsInViewport(
            fragmentViewMap: fragmentViewMap,
            viewportRange: viewportRange
        )

        guard !visibleFragmentViews.isEmpty else {
            return
        }

        // Count paragraphs before the viewport to determine starting line number
        let textElementsBeforeViewport = textContentManager.textElements(
            for: NSTextRange(
                location: textLayoutManager.documentRange.location,
                end: viewportRange.location
            )!
        )

        let startLineIndex = textElementsBeforeViewport.count
        var linesCount = 0

        for (layoutFragment, fragmentView) in visibleFragmentViews {
            // One custom view per paragraph (first text line fragment or extra line fragment)
            for textLineFragment in layoutFragment.textLineFragments where (textLineFragment.isExtraLineFragment || layoutFragment.textLineFragments.first == textLineFragment) {
                let lineNumber = startLineIndex + linesCount + 1
                let lineID = Self.gutterLineViewID(for: lineNumber)
                visibleIDs.insert(lineID)

                // Extract the paragraph text content, trimming the trailing newline
                let lineContent: String
                if let paragraph = layoutFragment.textElement as? NSTextParagraph {
                    var text = paragraph.attributedString.string
                    if text.hasSuffix("\n") {
                        text = String(text.dropLast())
                    }
                    lineContent = text
                } else {
                    lineContent = ""
                }

                let lineView = lineViewForID(lineID, in: container, dataSource: dataSource, lineNumber: lineNumber, lineContent: lineContent)

                // Size the gutter line view to cover only the text-content area,
                // excluding trailing lineSpacing. This ensures vertically-centered
                // gutter labels align with the text baseline region instead of being
                // pushed down by the lineSpacing gap below.
                // For extra line fragments, typographicBounds.height may be invalid (FB15131180);
                // fall back to the previous line fragment's height or typingLineHeight.
                let lineHeight: CGFloat
                let lineY: CGFloat
                if textLineFragment.isExtraLineFragment {
                    if layoutFragment.textLineFragments.count >= 2 {
                        let prevLineFragment = layoutFragment.textLineFragments[layoutFragment.textLineFragments.count - 2]
                        lineHeight = prevLineFragment.typographicBounds.height
                    } else {
                        lineHeight = typingLineHeight
                    }
                    lineY = fragmentView.frame.origin.y
                } else {
                    // Subtract the paragraph's lineSpacing so the gutter view height
                    // matches the text content area. When lineSpacing is 0 (default),
                    // this equals the full fragment view height.
                    // Try the line fragment's own paragraph style first, then fall back
                    // to the text view's defaultParagraphStyle (set via TypingStylePlugin
                    // or similar). This handles lines whose attributed string was rebuilt
                    // internally without preserving the original paragraph style.
                    let fragmentLineSpacing = (textLineFragment.attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.lineSpacing
                    let effectiveLineSpacing = fragmentLineSpacing ?? defaultParagraphStyle.lineSpacing
                    lineHeight = fragmentView.frame.size.height - effectiveLineSpacing
                    // Offset by typographicBounds.origin.y to match the built-in line
                    // number positioning (accounts for any top padding in the fragment).
                    lineY = fragmentView.frame.origin.y + textLineFragment.typographicBounds.origin.y
                }

                lineView.frame = CGRect(
                    origin: CGPoint(x: 0, y: lineY),
                    size: CGSize(width: customGutterWidth, height: lineHeight)
                ).pixelAligned

                linesCount += 1
            }
        }

        // Remove views for lines that scrolled out of the viewport
        pruneStaleLineViews(in: container, keeping: visibleIDs)

        // Draw trailing separator on top of all line views
        addCustomGutterSeparator(to: container)
    }

    // MARK: - Custom Gutter Reload

    /// Reloads all visible custom gutter line views by re-querying the data source.
    ///
    /// This is lighter-weight than setting `needsLayout = true` on the text view,
    /// because it only re-runs the custom gutter layout without affecting text layout.
    public func reloadGutterLineViews() {
        layoutCustomGutterLineViews()
    }

    /// Reloads the custom gutter line view for a specific line number.
    ///
    /// If the line is not currently visible in the viewport, this is a no-op.
    /// - Parameter lineNumber: The 1-based line number to reload.
    public func reloadGutterLineView(at lineNumber: Int) {
        guard let container = customGutterContainerView else { return }
        let lineID = Self.gutterLineViewID(for: lineNumber)
        if let existing = container.subviews.first(where: { $0.identifier == lineID }) {
            existing.removeFromSuperviewWithoutNeedingDisplay()
        }
        // Re-run full custom gutter layout to position the replacement view correctly
        // (we need fragment positions which are only available during layout enumeration)
        layoutCustomGutterLineViews()
    }

    /// Creates an identifier for a custom gutter line view at the given line number.
    private static func gutterLineViewID(for lineNumber: Int) -> NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(gutterLineViewIDPrefix + "\(lineNumber)")
    }

    /// Returns (or creates) a gutter line view for the given identifier.
    /// Always recreates the view from the data source to pick up captured SwiftUI state,
    /// but adds to the container first so the NSHostingView has a window before layout.
    private func lineViewForID(
        _ id: NSUserInterfaceItemIdentifier,
        in container: NSView,
        dataSource: any STGutterLineViewDataSource,
        lineNumber: Int,
        lineContent: String
    ) -> NSView {
        // Remove existing view for this line — it captured stale state
        if let existing = container.subviews.first(where: { $0.identifier == id }) {
            existing.removeFromSuperviewWithoutNeedingDisplay()
        }

        let lineView = dataSource.textView(self, viewForGutterLine: lineNumber, content: lineContent)
        lineView.identifier = id

        // Allow content (e.g. breakpoint badges) to extend beyond the
        // line view bounds. NSHostingView clips by default on macOS.
        lineView.clipsToBounds = false
        lineView.layer?.masksToBounds = false

        // Add to container BEFORE setting frame so the NSHostingView
        // has a window and can properly lay out its SwiftUI content.
        container.addSubview(lineView)

        return lineView
    }

    /// Removes gutter line views whose identifiers are not in the `keeping` set.
    private func pruneStaleLineViews(in container: NSView, keeping visibleIDs: Set<NSUserInterfaceItemIdentifier>) {
        for subview in container.subviews where subview.identifier != nil {
            guard let id = subview.identifier else { continue }
            let isLineView = id.rawValue.hasPrefix(Self.gutterLineViewIDPrefix)
            if isLineView && !visibleIDs.contains(id) {
                subview.removeFromSuperviewWithoutNeedingDisplay()
            }
        }
    }

    /// Adds (or updates) a vertical separator line on the trailing edge of the custom gutter container.
    private func addCustomGutterSeparator(to container: NSView) {
        // Remove existing separator
        if let existing = container.subviews.first(where: { $0.identifier == Self.gutterSeparatorID }) {
            existing.removeFromSuperviewWithoutNeedingDisplay()
        }

        guard let separatorColor = customGutterSeparatorColor, customGutterSeparatorWidth > 0 else {
            return
        }

        let separator = NSView(frame: CGRect(
            x: customGutterWidth - customGutterSeparatorWidth,
            y: 0,
            width: customGutterSeparatorWidth,
            height: container.bounds.height
        ))
        separator.identifier = Self.gutterSeparatorID
        separator.wantsLayer = true
        separator.layer?.backgroundColor = separatorColor.cgColor
        // Add behind line views so overhanging content (e.g. breakpoint badges)
        // draws in front of the separator, not behind it.
        container.addSubview(separator, positioned: .below, relativeTo: container.subviews.first)
    }
}

// MARK: - Custom Gutter Container

/// Flipped container view for custom gutter line views.
/// Uses flipped coordinates (top-to-bottom) to match document layout.
/// Does NOT clip to bounds so that per-line views can overhang past
/// the gutter edge (e.g. breakpoint badges with shadows).
private class STCustomGutterContainerView: NSView {

    override var isFlipped: Bool {
        true
    }

    override var isOpaque: Bool {
        false
    }

    override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        nil
    }

    override func mouseDown(with event: NSEvent) {
        // Consume — prevent click-through to the editor.
    }

    override func mouseDragged(with event: NSEvent) {
        // Consume — prevent drag-selection in the editor.
    }

    override func mouseUp(with event: NSEvent) {
        // Consume.
    }

    override func layout() {
        super.layout()

        // Workaround
        // FB21059465: NSScrollView horizontal floating subview does not respect insets
        // https://gist.github.com/krzyzanowskim/d2c5d41b86096ccb19b110cf7a5514c8
        if let enclosingScrollView = superview?.superview as? NSScrollView, enclosingScrollView.automaticallyAdjustsContentInsets {
            let topContentInset = enclosingScrollView.contentView.contentInsets.top
            if !topContentInset.isAlmostZero(), !topContentInset.isAlmostEqual(to: -topContentInset) {
                self.frame.origin.y = -topContentInset
            }
        }
    }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        // clipsToBounds left as default (false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
