#if canImport(UIKit)

import SwiftUI
import Testing
import UIKit
@testable import NumericTextField

/// Hosts a view in a key window and returns the backing `UITextField`.
/// The window must be kept alive for the duration of the test.
@MainActor
private func host<V: View>(_ view: V) throws -> (window: UIWindow, textField: UITextField) {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = UIHostingController(rootView: view)
    window.makeKeyAndVisible()
    window.layoutIfNeeded()
    let textField = try #require(window.firstSubview(of: UITextField.self))
    return (window, textField)
}

private extension UIView {
    func firstSubview<T: UIView>(of type: T.Type) -> T? {
        for subview in subviews {
            if let match = subview as? T ?? subview.firstSubview(of: type) {
                return match
            }
        }
        return nil
    }
}

@MainActor
@Suite struct EnvironmentTests {
    @Test func defaultsToLeadingBodyFontAndLabelColor() throws {
        let (window, textField) = try host(NumericTextField(value: .constant(1)))
        #expect(textField.textAlignment == .left)
        #expect(textField.font == .preferredFont(forTextStyle: .body))
        #expect(textField.textColor == .label)
        #expect(textField.isEnabled)
        #expect(textField.inputAccessoryView is UIToolbar)
        _ = window
    }

    @Test func followsMultilineTextAlignment() throws {
        let (window, textField) = try host(
            NumericTextField(value: .constant(1)).multilineTextAlignment(.trailing)
        )
        #expect(textField.textAlignment == .right)
        _ = window
    }

    @Test func trailingIsLeftInRightToLeft() throws {
        let (window, textField) = try host(
            NumericTextField(value: .constant(1))
                .multilineTextAlignment(.trailing)
                .environment(\.layoutDirection, .rightToLeft)
        )
        #expect(textField.textAlignment == .left)
        _ = window
    }

    @Test func followsDisabled() throws {
        let (window, textField) = try host(NumericTextField(value: .constant(1)).disabled(true))
        #expect(!textField.isEnabled)
        #expect(textField.textColor == .secondaryLabel)
        _ = window
    }

    @Test func customFontAndColorInheritFromContainer() throws {
        let font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        let (window, textField) = try host(
            VStack { NumericTextField(value: .constant(1)) }
                .numericTextFieldFont(font)
                .numericTextFieldColor(.red)
        )
        #expect(textField.font == font)
        #expect(textField.textColor == UIColor(Color.red))
        _ = window
    }

    @Test func dismissButtonCanBeHidden() throws {
        let (window, textField) = try host(
            NumericTextField(value: .constant(1)).numericTextFieldDismissButton(.hidden)
        )
        #expect(textField.inputAccessoryView == nil)
        _ = window
    }

    @Test func heightFollowsFontInsteadOfFixedFrame() throws {
        let large = UIFont.systemFont(ofSize: 60)
        let (window, textField) = try host(
            VStack { NumericTextField(value: .constant(1)) }.numericTextFieldFont(large)
        )
        #expect(textField.bounds.height >= large.lineHeight)
        _ = window
    }
}

@MainActor
private final class FocusBox {
    var isFocused = false
    var binding: Binding<Bool> {
        Binding(get: { self.isFocused }, set: { self.isFocused = $0 })
    }
}

@MainActor
@Suite struct FocusTests {
    @Test func bindingTrueFocusesField() async throws {
        let box = FocusBox()
        box.isFocused = true
        let (window, textField) = try host(NumericTextField(value: .constant(1), isFocused: box.binding))
        try await Task.sleep(for: .milliseconds(200))
        #expect(textField.isFirstResponder)
        _ = window
    }

    @Test func editingUpdatesBinding() throws {
        let box = FocusBox()
        let (window, textField) = try host(NumericTextField(value: .constant(1), isFocused: box.binding))
        #expect(textField.becomeFirstResponder())
        #expect(box.isFocused)
        textField.resignFirstResponder()
        #expect(!box.isFocused)
        _ = window
    }
}

#endif
