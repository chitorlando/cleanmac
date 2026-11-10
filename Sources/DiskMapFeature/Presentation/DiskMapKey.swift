/// The keys the disk map answers to.
enum DiskMapKey: Equatable, Sendable {
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
    case `return`

    /// The key with that virtual key code, or `nil` for any other key.
    ///
    /// Virtual key codes name a position on the keyboard, so they're the same in every
    /// layout. The Enter key of the numeric keypad has its own code and isn't Return.
    init?(keyCode: UInt16) {
        switch keyCode {
        case 126: self = .upArrow
        case 125: self = .downArrow
        case 123: self = .leftArrow
        case 124: self = .rightArrow
        case 36: self = .return
        default: return nil
        }
    }
}
