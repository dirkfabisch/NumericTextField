//
//  NumericInput.swift
//  NumericTextField
//
//  UI-independent validation, parsing and formatting rules
//  used by `NumericTextField`.
//

import Foundation

struct NumericInput {
    let maxIntegerDigits: Int
    let maxFractionDigits: Int
    let locale: Locale

    var decimalSeparator: String {
        locale.decimalSeparator ?? "."
    }

    /// Replaces any typed "." or "," with the locale's decimal separator.
    /// The decimal pad shows the separator of the keyboard's region, which
    /// may differ from `locale`; on a decimal pad either key means "decimal".
    func normalizingSeparators(_ string: String) -> String {
        string
            .replacingOccurrences(of: ".", with: decimalSeparator)
            .replacingOccurrences(of: ",", with: decimalSeparator)
    }

    /// Returns whether `text` is acceptable as the field's editing text.
    /// An empty string is valid (clears the value). Edits that shorten
    /// `previous` skip the digit limits, so an over-long value set from
    /// outside can still be corrected digit by digit.
    func isValid(_ text: String, replacing previous: String = "") -> Bool {
        if text.isEmpty { return true }
        let isShortening = text.count < previous.count

        let separator = decimalSeparator

        // Only digits and the decimal separator
        for char in text {
            if String(char) != separator && !char.isWholeNumber {
                return false
            }
        }

        let parts = text.components(separatedBy: separator)
        switch parts.count {
        case 1:
            return isShortening || text.count <= maxIntegerDigits
        case 2:
            return maxFractionDigits > 0
                && (isShortening
                    || (parts[0].count <= maxIntegerDigits && parts[1].count <= maxFractionDigits))
        default:
            return false
        }
    }

    /// Rounds half up (away from zero) to `maxFractionDigits`,
    /// matching what `formatForDisplay` / `formatForEditing` show.
    func rounded(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, maxFractionDigits, .plain)
        return result
    }

    func parse(_ text: String) -> Decimal? {
        guard !text.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.generatesDecimalNumbers = true
        formatter.usesGroupingSeparator = false
        return formatter.number(from: text)?.decimalValue
    }

    func formatForDisplay(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }

    func formatForEditing(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }
}
