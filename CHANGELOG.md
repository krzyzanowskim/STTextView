# Changelog

## [2.3.0] - 2025-12-23

### Added
- [macOS] Add snapshot tests for STTextView gutter rendering with various configurations
- [iOS] Add background blur effect to STGutterView when backgroundColor is nil
- [SwiftUI] Add environment-based lineHeightMultiple support in text views
- [SwiftUI] Add support for configurable lineHeightMultiple in TextView
- [SwiftUI/iOS] Add support for custom contentInsets to TextView
- [SwiftUI] Add showLineNumbers option and autocorrectionDisabled modifier to TextView
- [Shared] Expose contentFrame property to Plugins SPI

### Changed
- [iOS] Rename STContentView to STTextContainerView and add lightweight content size update
- [iOS] Optimize text view layout fragment rendering by reusing existing views
- [iOS] Adjust layout to respect textContainerInset in STTextView
- [iOS] Adjust viewportBounds to account for textContainerInset for better fragment coverage
- [iOS] Improve viewport bounds calculation to account for adjustedContentInset
- [iOS] Refactor gutter width adjustment logic to reduce redundant checks and improve layout stability
- [iOS] Make text, attributedText, and showsLineNumbers properties open and objc
- [macOS] Improve layout and drawing logic for STTextRenderView with clipsToContent support
- [macOS] Improve STTextRenderView layout to match actual rendering behavior
- [macOS] Improve selection image frame and origin during drag-and-drop
- [macOS] Adjust line fragment drawing position to account for line height multiple offset
- [macOS] Refactor STTextView layout system for improved viewport stability and accuracy
- [AppKit & UIKit] Ensure fragment views are marked for display when layout or rendering changes occur
- [SwiftUI] Refactor TextView options into shared TextViewOptions struct and extend platform support
- [SwiftUI] Refactor TextView view and coordinator for cleaner bindings and guard logic
- [SwiftUI] Optimize font updates in TextView by caching last applied font
- [Shared] Enable SwiftFormat with customized configuration and makefile tasks
- [Shared] Update platform and toolchain requirements
- Refactor README to consolidate and simplify SwiftUI usage documentation

### Fixed
- [iOS] Fix gutter alignment to scroll only vertically and remain fixed horizontally
- [iOS] Defer scrolling to selection until layoutSubviews for better layout consistency
- [macOS] Fix text view jumping by allowing growth of height but preventing shrinkage
- [macOS] Fix dynamic height adjustment and layout behavior in STTextView
- [macOS] Fix text view shrinkage and scroll issues when editing or resetting large documents
- [macOS] Fix layout issue for gutter view with NSScrollView content insets
- [macOS] Prevent text view from resizing below current scroll position
- [SwiftUI] Fix .wrapLines option logic and improve UI toggles and editable state handling
- [SwiftUI] Prevent selection change handling when isUpdating is true in TextViewRepresentable

## [2.2.8] - 2025-11-11

### Changed
- Adjust gutter width dynamically to fit line number text when viewport is visible
- Refine line number cell sizing and fix separator view rendering context
- Disable implicit layer animations in gutter views and improve gutter width handling
- Refactor gutter rendering for improved consistency and code clarity
- Fix gutter highlight position by clamping negative scroll offset
- Optimize gutter rendering by using sorted visible fragment views
- Refactor line selection logic to use STGutterCalculations.isLineSelected

## [2.2.7] - 2025-11-03

### Changed
- Refactor gutter line number rendering into shared utility function
- Improve gutter rendering by using layout fragment data instead of view-based mapping
- Sort visible fragment views by document order instead of vertical position

## [2.2.6] - 2025-11-03

### Changed
- Use fragment view frame for accurate gutter positioning of line numbers
- Apply pixel alignment to line fragment rectangles in gutter rendering
- Align marker views with visually centered line number text in gutter
- Fix baseline alignment for empty document by using typingAttributes for metrics
- Improve gutter view rendering and line number alignment in STTextView
- Fix gutter positioning and use caret location API in UITextInput methods
- Refactor gutter calculation logic into shared STGutterCalculations utility
- Refactor gutter width calculation to avoid layout issues during scrolling
- Adopt system text cursor in custom text views on macOS 14 and above
- Enable CATiledLayer backing for STContentViewportView
- Use CATiledLayer as backing layer for gutter-related views for better performance
- Use CATiledLayer as backing layer for STGutterView and STContentView
- Render gutterView as floating when possible by adding it to the scroll view

## [2.2.5] - 2025-11-01

### Changed
- Update to STTextKitPlus 0.2.0 and replace usage of location(...) with caretLocation(...)
- Improve double-click word selection to handle end-of-document cases
- Refine text selection granularity and rename local variable for clarity
- Fix range comparison to exclude end location in substring and attribute enumeration
- Enable vertical bounce in UITextView for improved scrolling experience

## [2.2.4] - 2025-10-23

### Changed
- Avoid layout suppression during bounce in layoutSubviews; move bounce check to didLayout
- Avoid layoutSubviews updates during bounce animations to preserve scroll behavior
- Fix line number gutter rendering and updating in both SwiftUI and UIKit text views
- Refactor gutter architecture with separate container views and improved marker layout

## [2.2.3] - 2025-10-14

### Changed
- Improve closestPosition(to:) fallback behavior when no layout location is found
- Extend willChangeTextHandler to include replacementString parameter

## [2.2.2] - 2025-10-14

### Changed
- Add NSRange-based replaceCharacters methods and undo coalescing support
- Expand willChangeTextHandler to include replacement string parameter
- Adjust trailing inset of gutter view from 4.0 to 6.0 for improved layout spacing
- Adjust marker view positioning and dragging frame in STGutterView
- Enable drag and drop to rearrange or remove gutter markers in STGutterView
- Improve gutter marker alignment and line number cell height calculations
- Simplify and replace custom SVG path for gutter marker indicator
- Refine gutter layout and marker appearance for better alignment and visibility
- Refactor gutter integration to support standalone layout and improve viewport handling
- Set scroll view background color to gridColor and update row highlight fill color

## [2.2.1] - 2025-10-01

### Changed
- Improve scrolling perf. Prevent recreating completion window
- Ensure gutter layout updates when toggling gutterVisibility property

## [2.2.0] - 2025-09-04

### Changed
- Update CHANGELOG. Release 2.2.0
- Fix attachment view positioning by setting full frame and skipping zero-sized frames
- Refactor textAttributedString(at:) to use textRange(for:enclosing:) instead of manual range creation
- Fix overflow check when detecting scroll position in layout controller delegate
- Improve gutter layout stability and viewport handling during layout
- Add FB19698121 to the list of known TextKit 2 issues in README
- Add debug visualization for layout viewport in STTextView
- Refactor text view layout to improve stability and eliminate redundant size updates
- Expand viewport layout and selection rendering to match view width
- Fix selection highlighting and layout when horizontally resizable
- Remove mise.toml configuration file including cargo tool dependencies
- Refactor STTextView to introduce contentViewportView for better layout separation
- Add support for rendering attributes for temporary text styling
- Improve whitespace glyph rendering and add ST_LAYOUT_DEBUG diagnostics
- Refactor viewport invalidation and rename parameter in scrollToVisible()
- Replace NSClipView bounds change observer with NSScrollView live scroll notification
- Refactor speech synthesizer and text container size handling for clarity
- Fix observer for usageBoundsForTextContainer and improve layout viewport logic
- Remove performance guidelines section from README

## [2.1.2] - 2025-08-05

### Changed
- Add LayoutViewport invalidation to STTextView for viewport layout updates
- Refactor attribute mutation methods and improve completion cancellation check
- Refactor completion view/window controllers and improve cleanup behavior
- Remove unused scrollViewFrameObserver property from STTextView
- Fix type casting for textStorage access in addAttributes method
- Add documentation for platform requirements, architecture, plugins, build, and performance

## [2.1.1] - 2025-07-05

### Changed
- Ensure gutterView is added as a floating subview of the enclosing scrollView

## [2.1.0] - 2025-07-04

### Changed
- Disable responsive scrolling and adjust overdraw heuristics in prepareContent(in:)
- Adjust content preparation granularity for STTextView rendering
- Avoid fatal error when setting invalid selection range in STTextView

## [2.0.9] - 2025-07-01

### Changed
- Update changelog for versions 2.0.8 and 2.0.9
- Improve layout invalidation logic after text attribute mutations
- Fix gutter cell Y-origin calculation by removing scrollView offset adjustments
- Fix gutter height calculation in STTextView to match content view height
- Simplify gutter layout and initialization logic in STTextView
- Remove redundant updateTypingAttributes() calls after text attribute edits
- Improve prepareContent overdraw logic to reduce layout recalculations
- Remove debug logging statements from layout and sizing methods

## [2.0.8] - 2025-06-19

### Changed
- Remove throttling logic for layout updates and delete the Throttler utility
- Preconfigure text container width in sizeToFit for wrapping mode
- Fix line number width calculation and update layout order in text view
- Bypass NSTextRange when applying attributes to improve reliability
- Accept dragged text from within and outside the text view in [#89](https://github.com/krzyzanowskim/STTextView/pull/89)
- Make text and attributedText properties open for subclassing
- Apply new foregroundColor to entire document when updated
- Apply new foregroundColor to existing text and update layout/display accordingly
- Update gutter view text color to match textColor for consistency
- Rename STTextLayoutRangeView to STTextRenderView and improve layout calculation
- Improve accessibility label generation and set gutter background color
- Add support for interactive text attachment views in STTextView

## [2.0.7] - 2025-05-19

### Changed
- Update changelog
- Annotate invalidating properties with @MainActor to ensure main-thread execution
- Implement UITextInput methods for position and range queries in STTextView
- Move scroll handling and scrollToVisible logic from STTextView.swift to STTextView+Scrolling.swift
- Improve prepareContent to preload more vertical content for smoother scrolling
- Add override for scroll(_:) to scroll contentView directly
- Improve centerSelectionInVisibleArea to better center zero-width selections
- Minor comment

## [2.0.6] - 2025-04-21

### Changed
- Update CHANGELOG
- Optimize insertion point rendering by reusing views and fixing layout issues
- Add support for canceling completions on selection change in STTextView
- Cancel autocompletion when clip view bounds change
- Improve completion cancellation logic by calling cancelComplete in more cases
- Move scrollView.documentView assignment earlier during scroll view setup

## [2.0.5] - 2025-04-19

### Changed
- Normalize lineHeightMultiple handling via stLineHeightMultiple helper method
- Improve scroll view styling and visibility in STCompletionViewController
- Make STCompletionViewController layout resizable and set default window size
- Add GitHub issue template configuration to disable blank issues
- Add Makefile with targets for changelog generation and help message
- Update changelog for versions 2.0.3 and 2.0.4, adjust git-cliff config and add mise setup

## [2.0.4] - 2025-03-30

### Changed
- Restrict typing attributes to allowed keys and initialize default attributes inline
- Add initial CHANGELOG.md with version history and notable changes
- Add git-cliff configuration file for changelog generation
- Make replaceCharacters methods open to allow overriding in subclasses
- Make textContentManager settable and STTextContentStorage subclassable
- Add FB17020435 to the list of TextKit 2 issues and bugs

## [2.0.3] - 2025-03-22

### Changed
- Implement missing accessibility setters
- Add accessibilitySharedCharacterRange method for STTextView
- Use monospaced font and fix text color across platforms
- Limit content load to maximum 4096 characters to improve performance

## [2.0.2] - 2025-03-13

### Changed
- Enhance accessibility support in STTextView
- Fix primaryTextLayoutManager memory issue and initialization order
- Fix textLayoutManager property and add setup method
- Make STTextContainer open and STTextLayoutManager replaceable
- Allow customizing text layout manager

### Fixed
- Fix NSAccessibility frame calculation for STTextView
- Use safer enumeration for accessibilityRange(forLine:)

## [2.0.1] - 2025-03-09

### Changed
- Fix handling for isEditable and isSelectable states
- Fix gutter view positioning and clipping
- Fix scroll view resizing behavior
- Fix text container size debug logging
- Fix clipsToBounds propagation to contentView and lineHighlightView
- Set completion task priority to userInitiated
- Add Task cancellation check in completion filtering
- Add async completion support to STTextView
- Improve appearance of completion menu items with better styling and layout
- Update version and remove known issues from README

## [2.0.0] - 2025-02-01

### Changed
- Fix precondition failure in addAttributes(_:range:updateLayout:)
- Moved NSRange clamped(_:) extension to common package
- Revert "Preserves position in line fragments when moving up and down "
- Improve completion UI appearance
- Update TextFormation plugin URL
- Add comment
- Update typing attributes immediately
- Simplify license description
- Insert newline using Unicode scalar to handle non-ASCII newline characters
- Add CONTRIBUTING.md with guidelines for proposing changes
- Separate gutter separator view from STGutterView
- Update size after layout
- Add trailing padding

## [2.0.0-beta5] - 2025-01-09

### Changed
- Add replaceCharacters(in:with:) that takes NSAttributedString
- Improve appearance of the gutter view
- Make backgroundColor optional
- Simplify STGutterView background color handling
- Derive gutter background color from text view appearance
- Capture view as NSImage and add bitmap representation
- Prevent title bar clipping content when using .fullSizeContentView windows in [#77](https://github.com/krzyzanowskim/STTextView/pull/77)
- Reduce viewport top inset
- Improve gutter line number cell layout and marker positioning
- Minor

## [2.0.0-beta4] - 2025-01-01

### Changed
- Improve viewport layout and sizing
- Fix prepareContent() crash with negative origin
- Prevent text attachment view from proxying interactions to content view
- Removed STDecorationView
- Fix dragging item frame

## [2.0.0-beta3] - 2024-12-31

### Changed
- Update readme
- Remove unused handlers
- Do not interpret any delete character while complete
- Don't interpret delete character in completion window
- Scroll to visible on content view
- Use contentView.visibleRect for gutter height
- Optimize viewport layout computation
- Position gutter view below horizontal scroller
- Utility is not public api
- Re-think size calculations
- Throttle live resize layouts
- Add throttler utility
- Adjust text container size calculation
- Add licensing information and commercial license alternative
- Add gutter markers
- Make the class open to allow subclassing
- Add comments explaining the view hierarchy
- NSView+Image extension for getting NSImage
- Fix layout calculation and image drawing
- Use STTextLayoutRangeView.image() for dragging image
- Handle optional textRange in STTextLayoutRangeView
- Introduce STTextLayoutRangeView and add isCompletionActive
- Improve completion handling
- Support dynamic colors in TextKit overlays
- Remove unused property
- Bump STTextView dependency to 1.0.0

## [2.0.0-beta2] - 2024-12-15

### Changed
- Add STTextFinderBarContainer to handle text finder bar
- Fix content view frame and origins for text selection and interaction
- Add contentFrame public property to STTextView
- Update Xcode version and window title
- Add gutter view below find bar in scroll view hierarchy
- Rename overlay view classes to be prefixed with ST
- Fit content width with gutter visible
- Add scrollView guard before using it in Gutter layouting
- Add @MainActor annotations to improve thread safety in completion handling

## [2.0.0-beta1] - 2024-09-29

### Changed
- Workaround FB15131180 - extra line fragment wrong frame
- ST_LAYOUT_DEBUG debugging environment
- Add extension to NSTextLayoutFragment for isExtraLineFragment property
- FB15131180 TextKit extra line frame is incorrect and does not respect layout fragment size
- Add iOS Plugin Loading in [#70](https://github.com/krzyzanowskim/STTextView/pull/70)
- Refactor gutter view calculations to use scroll view consistently and mark certain properties as @MainActor for thread safety. Adjust font and text color handling to ensure layout updates properly.
- Minor
- Remove troublesome layout call
- Use default layer
- Remove layout enforcement that triggered whole document layout
- Unify initial selection. match nstextview
- Update typing attributes after insert
- Don't change gutter font implicitly
- Missing pixel alignment
- Layout gutter values for empty document
- Update toolbar style
- Update demo apps
- Allow overdraw invisibles
- Rething sizeToFit
- Minor refactor. use default paragraph
- Rework line higlight from drawing to layer
- Update container size on contentView resize
- First resize, then layout
- Call private layout for element that is not laid out for drawing
- Viewport bounds from contentview
- Mark problem with layout
- Fix resizing contentView
- Typing attributes is read only
- Update highlight on selection change
- Update gutter when needed
- Redo/fix typing attributes and default font,color
- Hide isGutterVisible
- Update gutter on selection change
- Align gutter highligting
- _NS_4445425547
- Apply gutter background color
- Update README.md in [#64](https://github.com/krzyzanowskim/STTextView/pull/64)
- Layout on fragment update
- Update README
- Resize gutter to fit line numbers
- Minor
- Add toggle in toolbar
- Remove ruler, introduce working gutter with line numbers
- Layout gutter
- Layout gutter with bounds margin
- Layout viewport only on prepare content
- Setup overlay views
- Refactor gutter view
- Rename
- IsRulerVisible -> isGutterVisible
- Extend showsInvisibleCharacters to iOS
- ShowLineNumbers -> showsLineNumbers
- Expose textSelection public API
- Update public API
- Fixing Invisibles Characters Drawing in [#63](https://github.com/krzyzanowskim/STTextView/pull/63)
- Solidity gutter name
- Increase sample content.txt to 6.3M
- Fixing Invisibles Drawing Issues for Right-to-Left Writing Direction in [#62](https://github.com/krzyzanowskim/STTextView/pull/62)
- Supports commonly known IDE invisible characters. in [#59](https://github.com/krzyzanowskim/STTextView/pull/59)
- Update layout
- Make default separator color transparent
- Adjust gutter font size
- Setup adjusted font
- Cosmetics refactoring
- Update SwiftUI wrapper
- Exclude file on macos
- Update README.md
- Link FB14700414
- Terminated sponsorship
- Update for multiplatform swiftui wrappers
- Enable undo for iOS
- Move CoalescingUndoManager to shared domain
- Update README.md
- Add .editorconfig
- Keep line highlighting until selection change
- Select work action
- Select is not avail
- Implement standard actions
- UIResponderStandardEditActions placeholders
- Update README
- Unify common API under STTextViewProtocol
- Update README.md
- Update README.md
- Setup macCatalyst support
- Ios ruler higlight selection
- Sync gutter public api
- Update readme sample
- Update iOS ruler api
- Redo ruler view logic
- Rename
- Cleanup
- Minor refactor
- Check usesRuler
- Update readme
- ShowLineNumbers setup ruler
- Rename again
- Rename ruler -> gutter
- Replace runtime check
- Update backogrund color on trait update
- False
- Layout line numbers
- Rename
- Change ruler background
- Increase viewport horizontally to overdraw
- Layout attachment when layout available
- Add rulerView. Adjust layout and UITextInput rectangles
- Align sizint to contentview
- Expand content size to bounds
- SizeToFit update contentSize
- Update doc
- Layout queue
- Highlight selected line
- Update README.md
- Select begining of the document when set new text
- Rename
- Missing test file
- Initialize without selection
- Add comment
- Use new property
- Prepare per platform tests
- TextDelegate for textView
- Preserves position in line fragments when moving up and down in [#57](https://github.com/krzyzanowskim/STTextView/pull/57)
- Limit the selection
- Sync demo setup for both platforms
- Layout text attachments. Convenient insertText(_:replacementRange:)
- Preliminary markedText support
- Adjust condition
- Move STMarkedText to common module
- Add xcode scheme
- Switch to STTextInputTokenizer
- Get writing directon from layout manager
- USE_LAYERS_FOR_GLYPHS
- Add plugin interface. install delegates.
- Scroll after selection change
- Base writing direction
- Skip unecessary frame update
- Cleanup content scale
- Draw animated glyphs
- Line numbering - placeholder
- Provide validAttributesForMarkedText
- Toggle wrap mode
- Re-enable typing atributes on uikit
- Calculate container size
- Update readme
- Use tiled layer for content view
- Fix content view bounds
- Rename target
- Rename target
- Rename target
- AttributedText property
- TextEdit.xcworkspace
- YankingManager per instance
- DeleteBackward()
- Fix selection rectangles
- TextView.addAttributes
- Position insertion point
- Port pixelAligned to iOS
- Directional selection
- Remove unused view
- Assert text range location order
- Make selection work
- Implement more UITextInput methods
- Set content size after layout
- Set initial selection at the begining
- Disable overlay interaction
- Initial work to layout text fragments
- More placeholders
- More ui protocols implementation
- Removed too much
- Share more utils
- Add logger to ios module
- Share common layout related code
- Protocols stub
- Setup iOS/macOS target for TextEdit
- Reorganize package for dual platform modules

### Fixed
- Fix frame
- Fix frame
- Fix tests build
- Fix line number layer y position
- Fix wrap option
- Fix boundary recognition
- Test delegate

## [1.0.0] - 2024-06-13

### Changed
- Remove superfluous force cast. in [#56](https://github.com/krzyzanowskim/STTextView/pull/56)
- Change undo behaviour in [#53](https://github.com/krzyzanowskim/STTextView/pull/53)
- Small refactoring. in [#54](https://github.com/krzyzanowskim/STTextView/pull/54)
- Make selection navigation behave like other text editors. in [#51](https://github.com/krzyzanowskim/STTextView/pull/51)

## [0.9.5] - 2024-05-26

### Changed
- Bump dependency
- Use paragraphContentRange for highlighting that fixes the area
- Minors

## [0.9.4] - 2024-05-18

### Changed
- Support .cursor attribute
- Add support to link attribute
- Rely on rangeInElement for content range in element
- Add ifdef

## [0.9.3] - 2024-05-14

### Changed
- The use of CGContextSetFontSmoothingStyle is not permitted on the App Store

## [0.9.2] - 2024-05-10

### Changed
- Use estimated usageBoundsForTextContainer for vertical size
- Increase scroll overdraw area
- UsageBoundsForTextContainer is 🍌
- Comment usageBoundsForTextContainer situation
- Add marked text bug information

## [0.9.1] - 2024-04-28

### Changed
- Adjust font smoothing setting
- Layout attachments from NSTextAttachmentViewProvider
- Refactor plugin activation logic
- Update deprecated toolbar item size property
- Add coding initializers
- Default to CGPoint (no difference)
- Rename to better suite the purpose
- Group overlay subviews
- There's no poin tin STCompletion as a library
- Todo for one day
- More relying on layout manager content manager
- Use layout manager content manager
- Use layout manager range
- Minor comments

## [0.9.0] - 2024-02-05

### Changed
- Fix insertion point view on macOS < 14
- Rework frame sizing. sizeToFit.
- IsHorizontallyResizable/isVerticallyResizable

## [0.8.25] - 2024-01-28

### Changed
- Draw pixel aligned line highlight

## [0.8.24] - 2024-01-26

### Changed
- Check for missing viewport (when out of view)
- DefaultParagraphStyle got some love (again)

## [0.8.23] - 2024-01-14

### Changed
- Take enclosing scrollview visible rect or self visible rect into account when calculate viewport
- Perform initial layout for a view hidden inside scrollview
- Post accessibility selection change notification

## [0.8.22] - 2023-12-10

### Changed
- List highlight the biggest frame rect
- Mark STTextView with @objc
- Fixes typos in [#42](https://github.com/krzyzanowskim/STTextView/pull/42)
- Set textColor by default to text content

## [0.8.21] - 2023-10-22

### Changed
- Clean up the code around STInsertionPointProtocol in [#41](https://github.com/krzyzanowskim/STTextView/pull/41)
- Back to default anchors
- Rename completion types
- Fix path in xcode project
- Add runtime check for bounds workaround
- Remove insertionPointWidth. Support new system insertion view on macOS 14.

## [0.8.20] - 2023-10-20

### Changed
- Re-export STCompletion
- NSTextLayoutManager.usageBoundsForTextContainer observer is never trigerred
- Do not call reflectScrolledClipView that may cause random crashes
- Add padding to segment rectangle when scroll to location
- Rethink widthTracksTextView logic
- Workaround FB13290979
- Use default NSTextContainer size
- Remove segment frame workaround
- Add missing import
- Move STTextKitPlus to separate package
- Separate completion to STCompletion target/module
- Fix `HighlightView` `backgroundColor` in [#39](https://github.com/krzyzanowskim/STTextView/pull/39)
- NSTextContainer.size default value is not as documented

## [0.8.19] - 2023-10-11

### Changed
- Weird. text segment frame gets negative width on the edge of the viewport bounds

## [0.8.18] - 2023-10-11

### Changed
- Check segment frame against bounds
- Scroll after layout
- Highlight full width line
- Adjust width
- Shrink frame width on width tracking change
- Stretch higlihgt rect to full width
- NSTextContainer.size 0 means no limitation
- Refine highlight rectangle width

## [0.8.17] - 2023-10-09

### Changed
- Reset container size
- Use usageBoundsForTextContainer to adjust view frame
- Assert missing viewportRange
- Set intrinsicContentSize:
- Use STTextContainer
- Ruler text fragment ignores text container line fragment padding
- Draw highlihter at x0
- Fix a crash in deinit. in [#37](https://github.com/krzyzanowskim/STTextView/pull/37)

## [0.8.16] - 2023-10-05

### Changed
- Add plugins param to SwiftUI TextView init in [#34](https://github.com/krzyzanowskim/STTextView/pull/34)

## [0.8.15] - 2023-09-27

### Changed
- Fix invisibles position
- Fix drawing invisibles
- No need the workspace
- Update README.md
- Update README.md
- Allow to specify plugins in SwiftUI interface
- Removed extra ] in [#31](https://github.com/krzyzanowskim/STTextView/pull/31)

## [0.8.14] - 2023-09-14

### Changed
- Change workspace setup
- Mark Plugin protocols as MainActor 🙈 to please the compiler

## [0.8.13] - 2023-09-13

### Changed
- Change Plugin API - allow reference type plugin instance
- Strip out annotations code (feature to plugin)
- Comment layoutViewport issue
- Comment out unused overrides
- Create dynamic type in [#29](https://github.com/krzyzanowskim/STTextView/pull/29)
- Minor
- Plugin-TextFormation

## [0.8.12] - 2023-08-31

### Changed
- Always relay delegate calls to plugins

## [0.8.11] - 2023-08-27

### Changed
- Migrate to AVSpeechSynthesizer
- Exclude insertion points for text selection ranges
- Import Cocoa -> AppKit to please Swift 5.9
- ScrollableTextView accept frame

## [0.8.10] - 2023-08-21

### Changed
- Remove Plugins from Demo app
- Link external libraries
- Reference plugins
- OnDidLayoutViewport
- Fix attributes on returning attributed string
- Use more generic attributedString for document string
- Move NeonPlugin to separate repository
- Update README.md
- NeonPlugin
- Empty NeonPlugin
- Filter completions in sample app
- Allow chaining handlers
- CapitalizeWord, lowercaseWord, uppercaseWord
- Filter out modifier flags
- More plugin handlers
- Cleanup handlers
- Add events hadnler
- Change foundation API
- STPlugin is base plugin class
- Setup DummyPlagin as separate package
- Setup delegate proxy
- Setup dummy plugin
- Register plugins on the textview
- Demo app toggle invisibles
- Add emoji to the sample text
- Fix characters enumeration
- ^Space do not interfere with other shortcuts
- Codeql is not standard
- Remove redundant check
- Update features

## [0.8.9] - 2023-08-06

### Changed
- Option to showsInvisibleCharacters
- Substring loop fix
- Minors
- Update documentation. Adjust API
- Fix y position in wrapped text

## [0.8.8] - 2023-08-05

### Changed
- Deselect spellcheck selection on start typing
- More spellchecked related calls
- Variant of didChangeText with range
- Fix typing attributes on location in certain setup. Default spellcheck values
- Spellcheck improvements (hopefully, because no documentation)
- Don't set rendering attributes where regular attribute is expected
- Install decorationView for custom rendering attributes drawing
- Carefully workaround enumeratedattributes odds (FB12863947)
- Update README.md
- Update README.md
- Update README.md
- Store spellchecking annotations as rendering attributes only
- Update README
- Spell checker support
- Move isExtraLineFragment to STTextKitPlus
- Add selection to example

## [0.8.7] - 2023-07-29

### Changed
- Update selection binding
- STTextViewUI.TextView expose selection binding
- Post correct notification
- Fix swiftui timing updating initial text value
- Deprecate textDidChange
- SelectedTextRange
- Make NSTextLocation quasi-equatable public

## [0.8.6] - 2023-07-24

### Changed
- Fix highlighting of extra line fragment. Rework highlighting logic
- Improve numbers highlighting on edges
- Don't highlight when select
- Fix ruler higlight on empty document
- Note. possible workaround for unexpected layout frame size
- Unify selection logic
- Don't clear typing attributes in empty document
- Highlight line in all cases (when selection is at the end of the document)
- Return sorted insertion points
- Refine condition of empty document
- Length is already utf16, and faster
- Newline default to typing attribute
- Insert newline character with typing attributes
- It's typingLineHeight
- Adjust line numbers layout for empty document
- Workaround empty document segment frame height
- Calculate default line height without TextKit1
- Sometimes reported height is way above the final value for the document
- Frame height can only grow
- Update docs and defaults
- Use modernized API
- Minors

## [0.8.5] - 2023-07-17

### Changed
- Check for viewport range availability
- Disable certain string operations in Demo app due to performance reasons
- Improve/Fix find&replace
- Rework scrollToVisible routine to improve (hopefully) scrollin
- NSTextFinderClient minors
- Clamp highlight range because enumerateTextSegments is slow

### Fixed
- Fix clamped range

## [0.8.4] - 2023-07-16

### Changed
- Fix drawing multiple insertion points
- Layout on end live resize
- Minor display opt
- Calculate min/max X for viewport bounds
- Viewport width equals visible rect
- Fix condition
- Fix adjusted container width
- Use Natural Language to tag words
- Cancel completion task
- TextEdit demo provide simple list of words for autocompletion

## [0.8.3] - 2023-07-15

### Changed
- Minor
- Safely enumerate layout in the viewport

## [0.8.2] - 2023-07-13

### Changed
- NSCoder initializer is not available
- Make selectable for editable. disable editable when disable selectable
- ApproximateEquality is internal
- Move more public API to STTextKitPlus target
- STTextKitPlus library and target with public TextKit helpers
- Add readable/writeable pasteboard types
- Fix/Workaround deprecated pasteboard types handling
- Implement NSServicesMenuRequestor and use in copy&paste
- Invalid cursor
- Handle custom keyboard shortcut in performKeyEquivalent
- Minor
- Remove is any
- Remove insertion point on selection (improved)
- Remove insertion point view only if needed
- Refine custom completion view delegate
- Docs update
- Modernize completion API by embracing 'any protocol'
- Open default annotation class
- Default marked attributes to underline
- Full height insertion point
- Make STCompletionItem NSView based
- Remove redundant frame
- Completion item implementation provide a row view
- Rewrite completion row to SwiftUI Views
- Adjust completion window height
- Update completion content design
- Add shouldChangeText check to Delete in [#22](https://github.com/krzyzanowskim/STTextView/pull/22)
- Remove unecessary call
- Minor adjustments to the completion tableview
- Filter out empty range

## [0.8.1] - 2023-07-09

### Changed
- Set actual range
- Account for out of bounds range
- Fix finding character index at point

## [0.8.0] - 2023-07-09

### Changed
- REmove warning
- Rename file
- Add documentation
- Cleanup
- Do not expose internal type
- Update SwiftUI API to support modifiers-based styling
- Fix text two-way binding updates
- Refactor into custom gesture recognizer

## [0.7.2] - 2023-07-08

### Changed
- Refine drag selected text gesture
- Cancel long press gesture outside selection area
- Update README

## [0.7.1] - 2023-06-26

### Changed
- Handle drag gesture
- Draw a range
- Rename internal classess
- DragNdrop stub methods
- Fix segment frame calculation. Start STTextLayoutRangeView to draw selected fragment.
- Make default cursor more rounded
- Insertion point view goes on top of content view, as documented
- Default insertion point color uses accent color
- Demo app keep the annotation in the same place visually

## [0.7.0] - 2023-06-18

### Changed
- Improve the marked text undeline color handling
- Improve marked text logic
- Validate marked text attributes
- Rework Marked text handling
- MarkedText is a class
- Add Logger. Let text input context handle ecent first
- Use markedTextAttributes
- Apply macOS 14 highlight workaround
- Adjust highlight fill rect
- Draw background in bounds, not dirty rect (changed beh. on macOS 14)
- Move to NSView

## [0.6.9] - 2023-06-07

### Changed
- Unfortunately can't build on Xcode 14, so revert

## [0.6.8] - 2023-06-07

### Changed
- DefaultTextInsertionPoint uses system provided color on macOS 14
- Swift 5.9 is not my fault
- Handle underline(_:) action
- Build attributed string for the range onlyu
- Restrict font panel modes
- Create codeql.yml
- Revert inset change
- Account for horizontal inset (from ruler) to calculate content width
- InvalidateHashMarks already set needsDisplay

## [0.6.7] - 2023-05-28

### Changed
- Highlight whole fragment, not just a single line
- Update README
- Don't accept keyDown if not editable
- Change window title
- Rename module TextView -> STTextViewUI
- Call handleEvents on mouse events
- Add NSTextContent conformance
- Add different typografic to demo data

## [0.6.6] - 2023-05-23

### Changed
- Address/Fix selection glitches
- Update README
- Change args to optionset
- Update README

## [0.6.5] - 2023-05-21

### Changed
- Add just one annotation
- Add text attributes after setup ruler. Ruler uses textView.font that is affected by the first chracter attributes now
- Add test checking NSTextView behavior
- Fix typing attributes.
- Update typingAttribties at the insertion point. Add tests
- Annotation accept AttributedString
- Improve performance of attributedString
- Test builds
- Cleanup
- Simplify the logic
- Update typingAttributes on select
- Default to default typing attributes
- Deprecate defaultParagraphStyle
- DefaultTypingAttributes:
- Minor docs
- DidChangeText()
- IsCoalescingUndo

## [0.6.4] - 2023-05-14

### Changed
- Change api around attributed string to please compiler and NSTextInputClient conformance

## [0.6.3] - 2023-05-11

### Changed
- Move the NSTextInputClient implementation to the class to please the compiler

## [0.6.2] - 2023-05-06

### Changed
- HighlightSelectedLine parameter
- Expose replaceCharacters API
- Be more explicit with call
- Simplofy SwiftUI project. Display same content.
- Use AttributedString by default
- Separate SwiftUI project
- Update layers on window backing properties update
- Update insertion point visibility on become/resign key view
- Update text binding
- Start Speaking restart speaking
- Initialize speech synthesizer lazily
- Initias of TextView in SwiftUI
- Add missing headers
- Demo app got an icon
- Rename demo to TextEdit
- Update README.md

## [0.6.1] - 2023-04-30

### Changed
- Compatibility properties (always fasle)
- False update content size
- AllowsDocumentBackgroundColorChange:
- Refactor selectedRange implementations
- Add few NSText compatibility methods
- Add GNU Manifesto to sample text
- Set rendering attributes anyway. Simplify similar calls
- Apply font change for each font region
- Undo font change
- Check for editable
- Update layout from font panel
- Add comment
- Respond to changeColor from color panel
- Mark attributedString property nonobjc
- Espose attributedString as a property
- Add content updates tests
- Add tests target
- Layout annotations on text did change

### Fixed
- Fix selectors
- Test font changes
- Fix setAttributedString to call delegate and properly update storage

## [0.6.0] - 2023-04-24

### Changed
- Move annotations to the new STTextViewDataSource
- Bring back textContentStorage just to deprecate it
- Fix Storyboard warning
- Update README.md
- Fix setString

## [0.5.3] - 2023-04-23

### Changed
- Update annotations layout logic
- Update demo sample with new content
- Ode to STTextView
- Name demo bundle
- Make bunch of properties @objc dynamic

## [0.5.2] - 2023-04-23

### Changed
- Update interface for pasteAsRich
- Implement pasteAsRichText
- Re-use pasteAsPlainText
- Paste rich text as attributed string, and plain text as plain
- Copy attributed string
- Copy attributed string
- Rename textContentStorage -> textContentManager
- Add paste and select to context menu
- Support text speaking actions

## [0.5.1] - 2023-04-21

### Changed
- Handle Paste And Match Style (pasteAsPlainText)
- Fix paste on selection
- Merge attribtues
- Default to systeFontSize. Adjust ruler font attributes

## [0.5.0] - 2023-04-05

### Changed
- Respect replacementRange
- Improve undo after marked text change
- Improve marked text insertion support
- Initial work for better support of marked text
- Use NSRange.notFound just like system uses most of the time
- Remove isEditable checks that prevent set string value
- Ruler respect selectedLineTextAttributes for text attributed
- Insertion point only when editable
- Fix example
- SetAttributedString convenience method
- Minors
- Use text container bounds for selections
- Insertion point is no .visual
- Prevent setting insertion point when update string value
- Prepare for selection workaround
- Cleanup
- Set primary text layout manager
- Fix delete multiple cursor selection. Improve logic
- Yank, paste uses multiple cursors
- Use convenient methods to deal with bulk changes
- Simplify insert logic. Temporary disable multi-cursor insert
- Delete in order. Note selection reset bug
- Rename method
- Apply changes in order
- Multi-cursor selection. Multi-cursor editing preliminary support
- Option modify selection
- Deprecate insertionPointLocation (singular)

### Fixed
- Fix _fixSelectionAfterChangeInCharacterRange result

## [0.4.3] - 2023-02-22

### Changed
- More accessibility
- Set accessibility label
- Basic accessibility support
- Apply selected attributes to all selected lines
- Don't highlight lines with active selection
- Optimize drawing line highlight in ruler. Highlight all selected lines
- Resize markers after ruleThickness update
- Display after invalidate
- Enable markers in demo
- Update README
- Disallow markers by default
- Fix marker location to begin of the line
- Adjust marker location. Align to highlight
- AllowsMarkers property
- Add/Remove line markers
- Mark shape
- Do not shrink ruler
- Custom STRulerMaker
- DrawsBackground property
- Move to a folder
- Allow to provide custom undomanager
- Validate menu actions

## [0.4.2] - 2023-02-17

### Changed
- Check for delegate early
- Add location for menu customization delegate
- Allow to customize context menu with delegate
- Toggler ruler
- Cosmetics
- Reset cursor over annotation
- Implement specific workaround for NSTextContentStorage updates
- DidChangeText already called from replaceCharacters

## [0.4.1] - 2023-02-11

### Changed
- Cosmetic
- Update README
- Improve/Fix content insets updates
- Remove calls made by framework already
- Adjusts the receiver’s scrollers after scroll
- Rename filename
- Use ruler requiredThickness which has all thickness in it
- Cosmetics
- Find client improvement for viewport
- Use needsAnnotationsLayout:
- NSTextLayoutOrientationProvider
- Merge branch 'main' of github.com:krzyzanowskim/STTextView
- Update README.md
- Update README
- Update README
- Merge branch 'main' of github.com:krzyzanowskim/STTextView
- Update README.md
- Update README

## [0.4.0] - 2023-02-07

### Changed
- Fix layout loop caused by annotations updates. Update annotations only with needsAnnotationsLayout flag
- Temporary disable annotations because cause layout loop

## [0.3.3] - 2023-02-07

### Changed
- Fix content inset
- Update README.md

## [0.3.2] - 2023-02-04

### Changed
- A workaround (temporary) to escape layout() and layout annotations right after layout
- Restric annotations to viewport range

## [0.3.1] - 2023-02-04

### Changed
- Invalidate lines on selection change to re-highlight selected line

## [0.3.0] - 2023-02-04

### Changed
- Remove redundant needsLayout
- Remove redundant notifications.
- Optimize line number calculations
- Ensure layout to calculate frame height
- Revert
- Ensire will/did change text is not called inside editing transaction
- Guesswork on wth going on with layout
- Observe usageBoundsForTextContainer
- Workaround/Fix frame calculation
- Re-enable viewport for performance reason. breaks line ruler
- Avoid double layout

## [0.2.2] - 2023-01-29

### Changed
- Support yank
- Select word/line/paragraph replace current selection

## [0.2.1] - 2023-01-28

### Changed
- Revert contentInset. It doesn't work as expected
- Apply 10% margin when jump to position
- Improve selection
- Scroll to last selection
- Scroll to begin/end document
- Handle scroll by page
- Allow setup overscroll by setting contentInset

## [0.2.0] - 2023-01-24

### Changed
- Splitting the ruler padding into leading and trailing padding in [#10](https://github.com/krzyzanowskim/STTextView/pull/10)
- Minors
- Cosmetics
- Revert NSViewLayerContentScaleDelegate. layer delegate cause drawing issues
- NSTextSelectionNavigation.resolvedInsertionLocation sometimes crashes
- Rename property to (selectedLineTextColor
- Line number view inherit colors from text view
- Rename STLineNumberRulerView properties to match corresponding STTextView properties
- Annotation keep black color (on yellow background)
- Add content scale update notification
- Set editing cursor
- Refine STLineNumberRulerView initialization. ScrollView is optional
- Extend selection while holding shift
- Open completion view controller
- Cancel completion but don't break key input in parent window
- Cancel completion on any unhandled event
- ReplaceCharacters already calls willChangeText when needed
- Update README.md
- Update Demo
- Update
- Update README
- Adding option to extend the line highlighting to the ruler in [#9](https://github.com/krzyzanowskim/STTextView/pull/9)
- Info
- Link to EN wiki
- Link why SS is bad
- Add FB11898356 reference
- Add FB11898356
- ReplaceCharacters(in:) already call the will/didChangeText
- Merge branch 'marcin/didchange'
- Will/didChangeText is already called from replaceCharacters(in:
- Will/didChangeText called from one place on undo
- Rename delegate methods to match notification
- Add redo related fixme
- Improve coalescing undo. Always register undo on bread coalescing

## [0.1.2] - 2022-11-20

### Changed
- Register undo before break coalescing
- Do not break undo coalescing when undoing
- Do not register undo operation when undoing
- Mark yank reference for future
- Special treatment for extraLineFragment for empty document

## [0.1.1] - 2022-11-06

### Changed
- Stretch frame size to viewport size
- Add convenient methods to set attributes
- Update README.md

## [0.1.0] - 2022-10-08

### Changed
- Apply height baseline offset to the number ruler
- Center vertically in line height
- Customize layout fragment (for no good reason yet)
- Call textDidChange delegate
- By default lineHeightMultiple is 0
- Use useTypingAttributes attribute when requested

## [0.0.20] - 2022-09-22

### Changed
- Adjustable line number font
- Xcode Workspace
- Note about frame updates

## [0.0.19] - 2022-07-20

### Changed
- Change completion API to compile with Swift 5.6
- It's ok to deinit completion window controller
- Cleanup on close
- Align to the other version of the functin

## [0.0.18] - 2022-06-11

### Changed
- "inset" completion window position
- Clip main view
- Style completion window shape
- Close completion window on resign key of parent window
- Add completion API
- Add willChangeTextIn
- Update convenience API for segment frame
- Remove parameter label
- STAnnotationLabelView get a View as a label
- Merge pull request #3 from lukepistrol/feature/insertion-point-width in [#3](https://github.com/krzyzanowskim/STTextView/pull/3)
- Added property `insertionPointWidth`
- Missing comment tag
- Make insertionPointLayerClass an instance property
- Customization point for insertion
- Merge pull request #2 from lukepistrol/documentation in [#2](https://github.com/krzyzanowskim/STTextView/pull/2)
- Added doc comments to public/open properties/methods
- Public helper (sic)
- Update line annotation style
- Annotation truncation mode
- Merge pull request #1 from lukepistrol/feature/customization in [#1](https://github.com/krzyzanowskim/STTextView/pull/1)
- Inverted baseline offset
- Merge branch 'feature/ruler-view-customization' into feature/customization
- Property for separator color & baseline offset
- Added property for selectedLineHighlightColor & selectionBackgroundColor
- Open STLineAnnotation. Remove decoration from provided view.

## [0.0.17] - 2022-05-21

### Changed
- Make annotations public
- Update annotation API. Provide convenient STAnnotationLabelView

## [0.0.16] - 2022-05-21

### Changed
- Update README.md
- Adjust annotation font
- Use annotations
- Annotations API
- Setup annotation sublayer

## [0.0.15] - 2022-05-16

### Changed
- Add note about redo glitch
- Re-enable redo for normal operations
- Improve (rework) undo and coalescing

## [0.0.14] - 2022-05-08

### Changed
- Public
- ^Space -> complete:
- Register undo for insert text
- Check if scrollview is already attached

## [0.0.13] - 2022-05-06

### Changed
- Update container after live resize
- Disable viewport
- Remove needsViewportLayout
- Enable viewport bounds
- Refactor in separate file
- Ruler background color
- Use CATiledLayer for content and highlight

## [0.0.12] - 2022-05-05

### Changed
- Draw separator
- Draw only dirty rect
- Unclusterf layout pass
- Remove leftover property

## [0.0.11] - 2022-05-04

### Changed
- Invalidate line number cache to fix drawing glitch
- Update README.md
- Take padding into account
- Fix toggle text wrapping
- Fix frame/container size updates
- Figured how to update clipView to accomodate vertical ruler
- Minor refactoring
- Update text containers updates
- Use layoutFragmentFrame directly. Fix isDescendant(of
- Move files around
- Convenient STTextView.scrollableTextView()

## [0.0.10] - 2022-04-20

### Changed
- Fix content size update at extra line fragment
- TextContainer.lineFragmentPadding = 0 break extra line fragment
- Adjust text container width to the ruler view width

## [0.0.9] - 2022-04-18

### Changed
- Give some love to line number ruler.
- Round line horizontal values
- Align line numbers to the right
- Cache line numbers
- Minor cleanups
- Expose textFinder property for customization
- Update README.md

## [0.0.8] - 2022-04-16

### Changed
- Support Find&Replace
- Add Find feature. Setup NSTextFinderClient.

## [0.0.7] - 2022-04-12

### Changed
- TextSegmentRect return segment matching the typographic bounds
- Nailed layout issue. Can't fix it.
- Observe on main queue
- Autoresize layers
- Add missing, yet required initializer
- Minor. use operator
- Use window backingScaleFactor for the layers
- Adjust pixelAligned
- Minor refactoring to line number ruler
- Pixel aligned layers
- Transition rest of views to CALayer
- Move to CALayer for selections
- Adjust ruleThickness to max number line
- STLineNumberRulerView for line numbers ruler
- Add FB9971054
- Demo uses lorem ipsum content
- Link to commercial lincence purchase
- Update README.md
- Update README.md
- Minors

## [0.0.6] - 2022-03-31

### Changed
- Fix fragment location in the line
- Add bugreport
- Deprecate unused helpers
- Fix text fragment layout glitch, due to rounding
- Minor cleanup
- Rework line highlight drawing
- Workaround height for insertion point at empty document
- Set selection for empty content
- Fix selection ranges
- Disable insertion point when not first responder
- Did change text delegate. update attributes
- Fix tag

## [0.0.5] - 2022-03-27

### Changed
- Licence change to dual-licence
- Undo typing
- Fix delete selected range
- Delegate uses NSTextRange. User initiated changes uses internal shouldChangeText(in:string)
- InsertionPointColor:
- STText is useless
- Highlight full width
- Set container padding to 0
- Remove only insertion point
- Blink insertion point
- Select only if there's no prior selection
- Select region for context menu
- Show context menu
- Select on double tap

## [0.0.4] - 2022-02-26

### Changed
- Public -> open
- Fix first responder interaction
- Update README
- Update README
- Make first responder on mouse down
- Open class. Set background. Set selectedRange
- Update video

## [0.0.3] - 2022-02-25

### Changed
- Move mouse methods to separate file
- Fix scroll to selection interaction with drag to select
- Scroll to selection position
- Scroll visible to selection after change
- Scroll to selection after text did change
- Extend workaround
- Next barch of delete operations
- Implement more Delete operations
- TypingAttributes. Cleanup scrolling.
- Move code around
- Scroll to visible insertion point location

## [0.0.2] - 2022-02-20

### Changed
- Update README
- Fix Selection highlighting for non everlaping ranges
- Cup/paste/delete. fix selection range
- Copy selected string to clipboard
- Scroll to selection while select
- Update line highlight on keyboard selection change

## [0.0.1] - 2022-02-16

### Changed
- Initial Commit

