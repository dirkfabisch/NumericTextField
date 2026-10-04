# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Swift package (`swift-tools-version: 6.0`, iOS 17+) providing `NumericTextField`, a SwiftUI view for locale-aware decimal input bound to `Decimal?` (or `Decimal` via convenience init). MIT licensed. User-facing docs in `README.md` — keep its examples and behavior notes in sync with API changes. CI (`.github/workflows/ci.yml`) runs `swift test` on macOS and `xcodebuild test` on the first available iPhone simulator.

## Build

UIKit-dependent files (`NumericTextField.swift`, `NumericTextFieldPreview.swift`) are wrapped in `#if canImport(UIKit)`; `NumericInput` is Foundation-only. So `swift build` / `swift test` work on macOS (logic tests only, view compiled out), which is the fastest loop. Keep that split when adding files.

```sh
swift test                                   # logic tests on macOS
xcodebuild -scheme NumericTextField -destination 'generic/platform=iOS Simulator' build
```

For SwiftUI previews in Xcode, select an iOS simulator as run destination — the default "My Mac" compiles the view out.

Tests use Swift Testing and run on the iPhone 17 simulator (pin by UDID when comparing runs):

```sh
xcodebuild test -scheme NumericTextField -destination 'platform=iOS Simulator,name=iPhone 17'
# single suite/test: add -only-testing:NumericTextFieldTests/ValidationTests/germanAccepts
```

## Architecture

- `NumericTextField` (public SwiftUI `View`) is a thin wrapper around a private `UIViewRepresentable` (`NumericUITextField`) backed by `UITextField`. UIKit is used deliberately to get per-keystroke validation via `textField(_:shouldChangeCharactersIn:replacementString:)`, which SwiftUI's `TextField` can't do cleanly.
- **All input rules live in `NumericInput`** (`NumericInput.swift`, UIKit-free, covered by tests): `isValid` (only digits plus the locale's decimal separator, at most one separator, digit limits), `parse`, `formatForDisplay`, `formatForEditing`. Put new input logic there, not in the Coordinator, so it stays testable.
- The Coordinator's `shouldChangeCharactersIn` only builds the proposed text, asks `NumericInput.isValid`, and updates the binding on every accepted keystroke.
- **Typed `.` and `,` are both normalized to the locale's decimal separator**, because `.decimalPad` shows the keyboard region's separator, not `locale`'s. When normalization changed the input, the Coordinator sets the text and cursor itself and returns `false`.
- Edits that shorten the text bypass the digit limits, so over-long values set from outside stay editable.
- Rounding is half-up everywhere (`rounded`, both formatters). On focus, the binding is set to the rounded value, so what's shown is what's stored.
- **Two text formats:** while editing, text uses `formatForEditing` (no grouping separators, so validation stays simple); when not first responder it shows `formatForDisplay` (with grouping). Switching happens in `textFieldDidBegin/EndEditing`.
- `updateUIView` deliberately skips text updates while the field is first responder to avoid cursor jumps — external binding changes during editing are not reflected until editing ends.
- `maxFractionDigits == 0` switches the keyboard to `.numberPad` and rejects the separator.
- **Environment:** `updateUIView` → `applyEnvironment` reads `.multilineTextAlignment` (RTL-aware) and `.disabled`. SwiftUI's `.font`, `.foregroundStyle` and `.focused` can't be read by a `UIViewRepresentable` on iOS 17, so font, color and the dismiss toolbar use custom `@Entry` environment values set via the modifiers in `NumericTextFieldModifiers.swift`; focus uses the optional `isFocused: Binding<Bool>` init parameter (synced both ways in `applyFocus` and the delegate callbacks).
- Height comes from `sizeThatFits` (the field's intrinsic height), so it follows the font and Dynamic Type; no fixed frame.
- `NumericTextFieldViewTests` host the view in a real `UIWindow` and inspect the `UITextField` — use that pattern for UIKit-side behavior.
- The non-optional `Decimal` initializer maps `nil` (cleared field) to `.zero`.
