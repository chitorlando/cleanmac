import Foundation

extension CommandFailure {
    /// The error number `osascript` prints at the end of an AppleScript error, such as
    /// `-5000` in `99:117: execution error: Finder got an error: … (-5000)`, whatever the language.
    var appleScriptErrorCode: Int? {
        guard message.hasSuffix(")"), let open = message.lastIndex(of: "(") else { return nil }
        let number = message[message.index(after: open)..<message.index(before: message.endIndex)]
        return Int(number)
    }
}
