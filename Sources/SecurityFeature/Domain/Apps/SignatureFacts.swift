/// What the code signature of an app or a program says, before it's classified.
public struct SignatureFacts: Hashable, Sendable {
    /// Whether the signature is there and matches the code.
    public enum Validity: Hashable, Sendable {
        case valid
        case unsigned
        /// There is a signature, but the code or its resources no longer match it. Carries
        /// the Security framework's status, such as -67030 for a changed Info.plist.
        case invalid(status: Int32)
        /// The code couldn't be read, such as a program in a folder only root can open.
        case unreadable
    }

    public var validity: Validity
    /// Signed without any certificate, as the linker and `codesign -s -` do.
    public var isAdHoc = false
    /// The certificate chain ends at Apple's root, whoever the certificate was issued to.
    public var isIssuedByApple = false
    /// Signed by Apple itself, as macOS and Apple's apps are.
    public var isApple = false
    /// Signed by the App Store.
    public var isAppStore = false
    /// Signed with a Developer ID certificate, the kind for apps distributed outside the App Store.
    public var isDeveloperID = false
    /// Apple checked it for malware and issued a ticket, found on this Mac without going online.
    public var isNotarized = false
    /// The subject of the signing certificate, such as
    /// “Developer ID Application: Example Ltd (ABCDE12345)”.
    public var certificateSubject: String?
    public var teamID: String?

    public init(validity: Validity) {
        self.validity = validity
    }
}
