//
//  NumericTextFieldModifiers.swift
//  NumericTextField
//
//  Styling modifiers for `NumericTextField`. SwiftUI's own `.font` and
//  `.foregroundStyle` can't be read by a UIKit-backed view, so these
//  provide the equivalent through custom environment values. Like
//  `.font`, they apply to all numeric text fields in the modified view.
//

#if canImport(UIKit)

import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var numericTextFieldFont: UIFont? = nil
    @Entry var numericTextFieldColor: Color? = nil
    @Entry var numericTextFieldDismissButton: Visibility = .automatic
}

extension View {
    /// Sets the font of numeric text fields in this view.
    ///
    /// Pass a font created with `UIFont.preferredFont(forTextStyle:)` or
    /// scaled with `UIFontMetrics` to support Dynamic Type. `nil` restores
    /// the default body font.
    public func numericTextFieldFont(_ font: UIFont?) -> some View {
        environment(\.numericTextFieldFont, font)
    }

    /// Sets the text color of numeric text fields in this view.
    /// `nil` restores the default label color.
    public func numericTextFieldColor(_ color: Color?) -> some View {
        environment(\.numericTextFieldColor, color)
    }

    /// Shows or hides the dismiss button above the keyboard of numeric
    /// text fields in this view. Visible by default.
    public func numericTextFieldDismissButton(_ visibility: Visibility) -> some View {
        environment(\.numericTextFieldDismissButton, visibility)
    }
}

#endif
