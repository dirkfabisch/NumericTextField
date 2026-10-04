import Foundation
import Testing
@testable import NumericTextField

private let german = Locale(identifier: "de_DE")
private let english = Locale(identifier: "en_US")
private let french = Locale(identifier: "fr_FR")
private let swiss = Locale(identifier: "de_CH")

private func input(
    _ locale: Locale,
    integer: Int = 6,
    fraction: Int = 2
) -> NumericInput {
    NumericInput(maxIntegerDigits: integer, maxFractionDigits: fraction, locale: locale)
}

// MARK: - Validation

@Suite struct ValidationTests {
    @Test(arguments: ["", "0", "1", "123456", "1,", "1,5", "123456,99", ",5"])
    func germanAccepts(_ text: String) {
        #expect(input(german).isValid(text))
    }

    @Test(arguments: [
        "1.5",       // wrong separator for locale
        "1,2,3",     // more than one separator
        "1234567",   // too many integer digits
        "1234567,1", // too many integer digits with fraction
        "1,234",     // too many fraction digits
        "-1",        // no sign
        "1a",        // letters
        " 1",        // whitespace
        "1.000",     // grouping separator
    ])
    func germanRejects(_ text: String) {
        #expect(!input(german).isValid(text))
    }

    @Test(arguments: ["1.5", "123456.99", "1."])
    func englishAccepts(_ text: String) {
        #expect(input(english).isValid(text))
    }

    @Test(arguments: ["1,5", "1,000", "1.2.3"])
    func englishRejects(_ text: String) {
        #expect(!input(english).isValid(text))
    }

    @Test func zeroFractionDigitsRejectsSeparator() {
        let sut = input(german, fraction: 0)
        #expect(sut.isValid("123"))
        #expect(!sut.isValid("1,"))
        #expect(!sut.isValid("1,5"))
    }

    @Test func shorteningOverLongValueIsAllowed() {
        // Value set from outside exceeds the limits; deleting must still work
        let sut = input(english, integer: 3, fraction: 2)
        #expect(sut.isValid("12345", replacing: "123456"))
        #expect(sut.isValid("1234.5", replacing: "1234.56"))
        #expect(sut.isValid("1.234", replacing: "1.2345"))
    }

    @Test func growingOverLongValueIsRejected() {
        let sut = input(english, integer: 3, fraction: 2)
        #expect(!sut.isValid("1234567", replacing: "123456"))
        #expect(!sut.isValid("1234", replacing: "123"))
    }

    @Test func shorteningStillRejectsInvalidCharacters() {
        let sut = input(english, integer: 3)
        #expect(!sut.isValid("12a", replacing: "12345"))
        #expect(!sut.isValid("1.2.3", replacing: "1.2.345"))
    }

    @Test func integerLimitIsExact() {
        let sut = input(english, integer: 3)
        #expect(sut.isValid("999"))
        #expect(!sut.isValid("1000"))
        #expect(sut.isValid("999.99"))
    }
}

// MARK: - Separator normalization

@Suite struct NormalizationTests {
    @Test func germanTurnsDotIntoComma() {
        #expect(input(german).normalizingSeparators(".") == ",")
        #expect(input(german).normalizingSeparators(",") == ",")
    }

    @Test func englishTurnsCommaIntoDot() {
        #expect(input(english).normalizingSeparators(",") == ".")
        #expect(input(english).normalizingSeparators(".") == ".")
    }

    @Test func digitsAreUntouched() {
        #expect(input(german).normalizingSeparators("123") == "123")
    }

    @Test func normalizedSeparatorIsValid() {
        // English keyboard on a German-locale field: "1" + "." must work
        let sut = input(german)
        let proposed = "1" + sut.normalizingSeparators(".") + "5"
        #expect(sut.isValid(proposed))
        #expect(sut.parse(proposed) == Decimal(string: "1.5"))
    }
}

// MARK: - Parsing

@Suite struct ParsingTests {
    @Test func emptyIsNil() {
        #expect(input(german).parse("") == nil)
    }

    @Test func germanDecimal() {
        #expect(input(german).parse("1234,56") == Decimal(string: "1234.56"))
    }

    @Test func englishDecimal() {
        #expect(input(english).parse("1234.56") == Decimal(string: "1234.56"))
    }

    @Test func trailingSeparator() {
        #expect(input(german).parse("12,") == 12)
    }

    @Test func leadingSeparator() {
        #expect(input(german).parse(",5") == Decimal(string: "0.5"))
    }

    @Test func decimalPrecisionIsKept() {
        // Decimal must not go through Double (0.1 + 0.2 problem)
        #expect(input(english).parse("0.1") == Decimal(string: "0.1"))
    }
}

// MARK: - Formatting

@Suite struct FormattingTests {
    @Test func displayUsesGrouping() {
        let value = Decimal(string: "1234567.5")!
        #expect(input(german, integer: 9).formatForDisplay(value) == "1.234.567,5")
        #expect(input(english, integer: 9).formatForDisplay(value) == "1,234,567.5")
    }

    @Test func displayUsesLocaleSpecificGrouping() throws {
        let value = Decimal(string: "1234.5")!
        // Grouping characters vary between OS/ICU versions, so read them from the locale
        let frenchGrouping = try #require(french.groupingSeparator)
        let swissGrouping = try #require(swiss.groupingSeparator)
        #expect(input(french).formatForDisplay(value) == "1\(frenchGrouping)234,5")
        #expect(input(swiss).formatForDisplay(value) == "1\(swissGrouping)234.5")
    }

    @Test func editingHasNoGrouping() {
        let value = Decimal(string: "1234567.5")!
        #expect(input(german, integer: 9).formatForEditing(value) == "1234567,5")
        #expect(input(english, integer: 9).formatForEditing(value) == "1234567.5")
    }

    @Test func noTrailingZeros() {
        #expect(input(german).formatForDisplay(12) == "12")
        #expect(input(german).formatForEditing(Decimal(string: "12.5")!) == "12,5")
    }

    @Test func roundsToMaxFractionDigits() {
        let value = Decimal(string: "1.23456")!
        #expect(input(english).formatForDisplay(value) == "1.23")
    }

    @Test func roundsHalfUp() {
        let sut = input(english)
        #expect(sut.formatForDisplay(Decimal(string: "0.125")!) == "0.13")
        #expect(sut.formatForDisplay(Decimal(string: "0.135")!) == "0.14")
        #expect(sut.formatForEditing(Decimal(string: "0.125")!) == "0.13")
    }

    @Test func roundedMatchesFormatting() {
        let sut = input(english)
        #expect(sut.rounded(Decimal(string: "1.23456")!) == Decimal(string: "1.23"))
        #expect(sut.rounded(Decimal(string: "0.125")!) == Decimal(string: "0.13"))
        #expect(sut.rounded(Decimal(string: "1.5")!) == Decimal(string: "1.5"))
        #expect(input(english, fraction: 0).rounded(Decimal(string: "2.5")!) == 3)
    }

    @Test(arguments: ["0", "1,5", "123456,99", "42"])
    func editingRoundTrips(_ text: String) throws {
        let sut = input(german)
        let value = try #require(sut.parse(text))
        #expect(sut.formatForEditing(value) == text)
        #expect(sut.isValid(sut.formatForEditing(value)))
    }
}
