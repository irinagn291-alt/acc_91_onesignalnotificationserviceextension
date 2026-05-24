import Foundation

enum VaultISBNNormalizer {
    static func canonicalDigits(_ raw: String) -> String {
        raw.filter { $0.isNumber }
    }

    static func looksLikeISBN(_ text: String) -> Bool {
        let digits = canonicalDigits(text)
        return digits.count == 13 || digits.count == 10
    }

    static func normalizedISBN(fromScanned raw: String) -> String? {
        let digits = canonicalDigits(raw)
        if digits.count == 13 || digits.count == 10 { return digits }
        return nil
    }
}
