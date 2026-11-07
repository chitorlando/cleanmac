import Foundation

extension String {
    /// Characters a POSIX shell never treats specially, so words made only of them need no quotes.
    private static let shellSafeCharacters = Set(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@%+=:,./_-"
    )

    /// The string as a single POSIX shell word that the shell reads back literally.
    /// Anything unusual goes inside single quotes, where only the single quote itself
    /// needs escaping, as `'\''`.
    var shellQuoted: String {
        if !isEmpty, allSatisfy(Self.shellSafeCharacters.contains) {
            return self
        }
        return "'" + replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }
}
