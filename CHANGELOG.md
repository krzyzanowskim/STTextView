# Changelog

## [2.0.2] - 2025-03-13

### 🚀 Features

- Feat: enhance accessibility support in STTextView

The commit extends NSAccessibilityProtocol implementation in STTextView by adding
support for NSAccessibilityStaticText and NSAccessibilityNavigableStaticText
protocols. It implements frame, line positioning, and range methods to improve
screen reader compatibility and navigation capabilities within text content.

### 🐛 Bug Fixes

- Fix: Use safer enumeration for accessibilityRange(forLine:)

The existing code used textElements(for:) which can return an empty array. This patch uses enumerateTextElements(from:) instead, which is safer since it can enumerate elements starting at a given location without the risk of an empty result.
- Fix NSAccessibility frame calculation for STTextView

The fix ensures that accessibilityFrame(for:) returns coordinates in screen space
by properly converting the text segment frame through the view hierarchy to screen
coordinates.

## [2.0.0-beta5] - 2025-01-09

### 🚜 Refactor

- Refactor: derive gutter background color from text view appearance

The gutter background color now updates whenever the text view appearance
changes. This ensures the gutter always matches the text view as the system
appearance changes between light and dark mode.

Also moved a few appearance-related updates into the appearance change
callback to keep them together.

## [2.0.0-beta3] - 2024-12-31

### 🚜 Refactor

- Refactor: Use STTextLayoutRangeView.image() for dragging image

Extract getting the dragging image for a text range into the
STTextLayoutRangeView.image() method. This avoids duplicating the bitmap
image rep caching logic.

## [2.0.0-beta1] - 2024-09-29

### 🐛 Bug Fixes

- Fix boundary recognition
- Fix wrap option
- Fix line number layer y position
- Fix tests build
- Fix frame
- Fix frame

### 🚜 Refactor

- Refactor gutter view

### 🧪 Testing

- Test delegate

## [0.8.5] - 2023-07-17

### 🐛 Bug Fixes

- Fix clamped range

## [0.8.2] - 2023-07-13

### 📚 Documentation

- Docs update

## [0.6.1] - 2023-04-30

### 🐛 Bug Fixes

- Fix setAttributedString to call delegate and properly update storage
- Fix selectors

### 🚜 Refactor

- Refactor selectedRange implementations

### 🧪 Testing

- Test font changes

## [0.5.0] - 2023-04-05

### 🐛 Bug Fixes

- Fix _fixSelectionAfterChangeInCharacterRange result

