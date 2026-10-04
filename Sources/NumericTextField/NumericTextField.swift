//
//  NumericTextField.swift
//  NumericTextField
//
//  A locale-aware numeric text field that restricts input to digits
//  and the locale-appropriate decimal separator. Configurable for
//  maximum integer and fraction digits.
//

#if canImport(UIKit)

import SwiftUI
import UIKit

// MARK: - Public API

/// A text field that only accepts numeric input with locale-aware decimal separators.
///
/// The field restricts keyboard input to digits and the decimal separator
/// of `locale` (e.g. "," for German, "." for English). A typed "." or ","
/// is always treated as the decimal separator.
///
/// - Parameters:
///   - value: A binding to the optional `Decimal` value.
///   - maxIntegerDigits: Maximum number of digits before the decimal separator.
///   - maxFractionDigits: Maximum number of digits after the decimal separator.
///   - placeholder: Placeholder text shown when the field is empty.
///   - locale: The locale used for formatting. Defaults to `.autoupdatingCurrent`.
///   - isFocused: Optional binding that reflects and controls keyboard focus.
///
/// The field respects `.multilineTextAlignment(_:)` and `.disabled(_:)`.
/// Use `.numericTextFieldFont(_:)`, `.numericTextFieldColor(_:)` and
/// `.numericTextFieldDismissButton(_:)` for styling.
///
/// Example:
/// ```swift
/// @State private var price: Decimal?
/// NumericTextField(value: $price, maxIntegerDigits: 6, maxFractionDigits: 2)
///     .multilineTextAlignment(.trailing)
/// ```
public struct NumericTextField: View {
    @Binding var value: Decimal?

    let maxIntegerDigits: Int
    let maxFractionDigits: Int
    let placeholder: String
    let locale: Locale
    let isFocused: Binding<Bool>?

    public init(
        value: Binding<Decimal?>,
        maxIntegerDigits: Int = 9,
        maxFractionDigits: Int = 2,
        placeholder: String = "",
        locale: Locale = .autoupdatingCurrent,
        isFocused: Binding<Bool>? = nil
    ) {
        self._value = value
        self.maxIntegerDigits = maxIntegerDigits
        self.maxFractionDigits = maxFractionDigits
        self.placeholder = placeholder
        self.locale = locale
        self.isFocused = isFocused
    }

    public var body: some View {
        NumericUITextField(
            value: $value,
            maxIntegerDigits: maxIntegerDigits,
            maxFractionDigits: maxFractionDigits,
            placeholder: placeholder,
            locale: locale,
            isFocused: isFocused
        )
    }
}

// MARK: - Convenience Initializer for non-optional Decimal

extension NumericTextField {
    /// Convenience initializer that works with a non-optional `Decimal` binding.
    public init(
        value: Binding<Decimal>,
        maxIntegerDigits: Int = 9,
        maxFractionDigits: Int = 2,
        placeholder: String = "",
        locale: Locale = .autoupdatingCurrent,
        isFocused: Binding<Bool>? = nil
    ) {
        self._value = Binding(
            get: { value.wrappedValue },
            set: { value.wrappedValue = $0 ?? .zero }
        )
        self.maxIntegerDigits = maxIntegerDigits
        self.maxFractionDigits = maxFractionDigits
        self.placeholder = placeholder
        self.locale = locale
        self.isFocused = isFocused
    }
}

// MARK: - UIViewRepresentable

private struct NumericUITextField: UIViewRepresentable {
    @Binding var value: Decimal?

    let maxIntegerDigits: Int
    let maxFractionDigits: Int
    let placeholder: String
    let locale: Locale
    let isFocused: Binding<Bool>?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = maxFractionDigits > 0 ? .decimalPad : .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = true
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Keyboard accessory with dismiss button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let dismissButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.dismissKeyboard)
        )
        dismissButton.accessibilityLabel = "Dismiss keyboard"
        toolbar.items = [spacer, dismissButton]
        context.coordinator.toolbar = toolbar

        // Show formatted value on initial display
        if let value {
            textField.text = formatForDisplay(value)
        }

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        applyEnvironment(context.environment, to: textField, toolbar: context.coordinator.toolbar)
        applyFocus(to: textField)

        // Only update text when not actively editing to avoid cursor jumps
        guard !textField.isFirstResponder else { return }
        if let value {
            textField.text = formatForDisplay(value)
        } else {
            textField.text = nil
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        let intrinsic = uiView.intrinsicContentSize
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? intrinsic.width
        return CGSize(width: width, height: intrinsic.height)
    }

    private func applyEnvironment(_ environment: EnvironmentValues, to textField: UITextField, toolbar: UIToolbar?) {
        let isRightToLeft = environment.layoutDirection == .rightToLeft
        switch environment.multilineTextAlignment {
        case .leading: textField.textAlignment = isRightToLeft ? .right : .left
        case .center: textField.textAlignment = .center
        case .trailing: textField.textAlignment = isRightToLeft ? .left : .right
        }

        textField.isEnabled = environment.isEnabled
        textField.font = environment.numericTextFieldFont ?? .preferredFont(forTextStyle: .body)
        if !environment.isEnabled {
            textField.textColor = .secondaryLabel
        } else {
            textField.textColor = environment.numericTextFieldColor.map(UIColor.init) ?? .label
        }

        let accessory = environment.numericTextFieldDismissButton == .hidden ? nil : toolbar
        if textField.inputAccessoryView !== accessory {
            textField.inputAccessoryView = accessory
            if textField.isFirstResponder {
                textField.reloadInputViews()
            }
        }
    }

    private func applyFocus(to textField: UITextField) {
        guard let isFocused else { return }
        if isFocused.wrappedValue, !textField.isFirstResponder {
            // Not in a window yet during the first update, so defer
            Task { @MainActor in
                textField.becomeFirstResponder()
            }
        } else if !isFocused.wrappedValue, textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumericUITextField
        var toolbar: UIToolbar?

        init(parent: NumericUITextField) {
            self.parent = parent
        }

        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.isFocused?.wrappedValue == false {
                parent.isFocused?.wrappedValue = true
            }

            // Switch to editing format (no grouping separators)
            if let value = parent.value {
                textField.text = parent.formatForEditing(value)

                // Align the binding with what is shown, so excess fraction
                // digits set from outside don't survive an edit unseen
                let rounded = parent.input.rounded(value)
                if rounded != value {
                    parent.value = rounded
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFocused?.wrappedValue == true {
                parent.isFocused?.wrappedValue = false
            }

            // Switch to display format (with grouping separators)
            if let value = parent.value {
                textField.text = parent.formatForDisplay(value)
            } else {
                textField.text = nil
            }
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return false }
            let replacement = parent.input.normalizingSeparators(string)
            let proposedText = currentText.replacingCharacters(in: textRange, with: replacement)

            guard parent.input.isValid(proposedText, replacing: currentText) else { return false }
            parent.value = parent.input.parse(proposedText)
            if replacement == string { return true }

            // The typed separator was normalized, so apply the edit ourselves
            textField.text = proposedText
            let cursorOffset = range.location + (replacement as NSString).length
            if let position = textField.position(from: textField.beginningOfDocument, offset: cursorOffset) {
                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }
            return false
        }
    }

    // MARK: - Helpers

    var input: NumericInput {
        NumericInput(
            maxIntegerDigits: maxIntegerDigits,
            maxFractionDigits: maxFractionDigits,
            locale: locale
        )
    }

    func formatForDisplay(_ value: Decimal) -> String {
        input.formatForDisplay(value)
    }

    func formatForEditing(_ value: Decimal) -> String {
        input.formatForEditing(value)
    }
}

#endif
