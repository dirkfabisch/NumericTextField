# NumericTextField

A SwiftUI text field for decimal numbers that validates every keystroke. Input is limited to digits and the locale's decimal separator, with configurable integer and fraction digit limits. The value is bound as `Decimal`, so there are no floating-point rounding errors.

```swift
@State private var price: Decimal?

NumericTextField(value: $price, maxIntegerDigits: 6, maxFractionDigits: 2)
```

## Features

- Validates per keystroke: only digits and one decimal separator, within the digit limits
- Locale-aware: `1.234,5` in German, `1,234.5` in English. A typed `.` or `,` always counts as the decimal separator, so the field works with any keyboard region.
- Binds to `Decimal?` or `Decimal`
- Shows grouping separators while not editing and plain digits while editing
- Rounds half up (`0.125` → `0.13`)
- Follows `.multilineTextAlignment` (including right-to-left) and `.disabled`
- Styling modifiers for font, text color and the keyboard dismiss button
- Optional focus binding

## Requirements

- iOS 17+
- Swift 6 / Xcode 16+

On other platforms the package compiles, but the view is not available.

## Installation

In Xcode, choose **File → Add Package Dependencies…** and enter the repository URL. In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dirkfabisch/NumericTextField.git", from: "0.1.0")
]
```

## Usage

### Optional and non-optional values

```swift
@State private var amount: Decimal?   // cleared field → nil
@State private var quantity: Decimal = 1 // cleared field → 0

NumericTextField(value: $amount, placeholder: "0.00")
NumericTextField(value: $quantity, maxIntegerDigits: 4, maxFractionDigits: 0)
```

With `maxFractionDigits: 0` the field shows a number pad without a separator key.

### Locale

The field uses `Locale.autoupdatingCurrent` by default. Pass a locale to fix the format:

```swift
NumericTextField(value: $amount, locale: Locale(identifier: "de_DE"))
```

### Alignment and styling

```swift
Form {
    NumericTextField(value: $net)
    NumericTextField(value: $gross)
}
.multilineTextAlignment(.trailing)
.numericTextFieldFont(.monospacedDigitSystemFont(ofSize: 17, weight: .regular))
.numericTextFieldColor(.blue)
.numericTextFieldDismissButton(.hidden)
```

Like `.font`, these modifiers apply to all numeric text fields in the modified view. SwiftUI's own `.font` and `.foregroundStyle` have no effect, because the field is backed by `UITextField`. For a custom font to follow Dynamic Type, create it with `UIFont.preferredFont(forTextStyle:)` or scale it with `UIFontMetrics`.

### Focus

```swift
@State private var isEditing = false

NumericTextField(value: $amount, isFocused: $isEditing)
Button("Edit") { isEditing = true }
```

The binding works in both directions. It is independent of `@FocusState`.

## Behavior notes

- **Values set from outside** with more fraction digits than allowed are shown rounded. When the field gains focus, the binding is set to the rounded value.
- **Values exceeding `maxIntegerDigits`** stay editable: deleting is always possible, adding digits is not.
- **External changes during editing** are not shown until editing ends. This avoids cursor jumps.
- **Pasted text** is treated like typed text: every `.` and `,` counts as a decimal separator. Grouped numbers like `1.234,56` are therefore rejected. `1.234` is read as 1.234 if `maxFractionDigits` allows three digits.

## Limitations

- Negative numbers are not supported.
- There is no `.onSubmit` support. The decimal pad has no return key.

## License

MIT, see [LICENSE](LICENSE).
