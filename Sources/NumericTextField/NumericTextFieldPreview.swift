//
//  NumericTextFieldPreview.swift
//  NumericTextField
//
//  Interactive preview for manually checking keyboard behavior:
//  separator normalization, rounding on focus, over-long values.
//

#if canImport(UIKit)

import SwiftUI

private struct PreviewRow<Field: View>: View {
    let title: String
    let value: Decimal?
    @ViewBuilder let field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                field
            }
            Text("Binding: \(value.map { "\($0)" } ?? "nil")")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("NumericTextField") {
    @Previewable @State var german: Decimal? = Decimal(string: "1234.5")
    @Previewable @State var english: Decimal?
    @Previewable @State var integer: Decimal = 42
    @Previewable @State var external: Decimal? = Decimal(string: "1.23456")
    @Previewable @State var styled: Decimal? = 99
    @Previewable @State var isFocused = false
    @Previewable @State var isDisabled = false

    Form {
        Section("Locales") {
            PreviewRow(title: "de_DE", value: german) {
                NumericTextField(value: $german, locale: Locale(identifier: "de_DE"))
            }
            PreviewRow(title: "en_US", value: english) {
                NumericTextField(value: $english, placeholder: "0.00", locale: Locale(identifier: "en_US"))
            }
        }

        Section("No fraction, non-optional") {
            PreviewRow(title: "Integer", value: integer) {
                NumericTextField(value: $integer, maxIntegerDigits: 4, maxFractionDigits: 0)
            }
        }

        Section {
            PreviewRow(title: "Max 3,2", value: external) {
                NumericTextField(value: $external, maxIntegerDigits: 3, maxFractionDigits: 2)
            }
            Button("Set 1.23456 (rounds on focus)") { external = Decimal(string: "1.23456") }
            Button("Set 0.125 (half up → 0.13)") { external = Decimal(string: "0.125") }
            Button("Set 123456 (over limit, delete must work)") { external = 123456 }
            Button("Set nil") { external = nil }
        } header: {
            Text("Values set from outside")
        } footer: {
            Text("Focus the field after setting a value and watch the binding.")
        }

        Section("Styling & focus") {
            PreviewRow(title: "Styled", value: styled) {
                NumericTextField(value: $styled, isFocused: $isFocused)
                    .multilineTextAlignment(.trailing)
                    .numericTextFieldFont(.monospacedDigitSystemFont(ofSize: 22, weight: .semibold))
                    .numericTextFieldColor(.blue)
                    .numericTextFieldDismissButton(.hidden)
                    .disabled(isDisabled)
            }
            Toggle("Focused", isOn: $isFocused)
            Toggle("Disabled", isOn: $isDisabled)
        }
    }
    .multilineTextAlignment(.trailing)
}

#endif
