import Foundation
import Security

/// `CodeSignatureInspecting` backed by the Security framework, checking a signature the way
/// `codesign --verify` does: the code and its sealed resources must match it. As
/// `CodeIdentityReading`, it only reads what the signature declares, as `codesign --display` does.
///
/// It never goes online: revocations and notarization tickets are only looked up in what this
/// Mac already knows, such as a ticket stapled to the app.
public struct SecurityFrameworkSignatureInspector: CodeSignatureInspecting, CodeIdentityReading {
    /// What each kind of signer must satisfy, in Apple's code requirement language.
    private enum Requirement {
        static let issuedByApple = "anchor apple generic"
        static let apple = "anchor apple"
        static let appStore = "anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.9] exists"
        static let developerID = "anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists"
            + " and certificate leaf[field.1.2.840.113635.100.6.1.13] exists"
        static let notarized = "notarized"
    }

    /// Keys of the signing information, the values of `kSecCodeInfoFlags`,
    /// `kSecCodeInfoCertificates`, `kSecCodeInfoTeamIdentifier`, `kSecCodeInfoUnique` and
    /// `kSecCodeInfoCdHashes`.
    private enum InfoKey {
        static let flags = "flags"
        static let certificates = "certificates"
        static let teamID = "teamid"
        static let cdHash = "unique"
        static let cdHashes = "cdhashes"
    }

    private static var validation: SecCSFlags { .noNetworkAccess }
    /// Once the signature is known to be valid, requirements only need its certificates.
    private static var requirementCheck: SecCSFlags {
        SecCSFlags(rawValue: SecCSFlags.noNetworkAccess.rawValue | UInt32(kSecCSDoNotValidateResources))
    }

    public init() {}

    public func facts(forCodeAt url: URL) -> SignatureFacts {
        guard let code = staticCode(at: url) else { return SignatureFacts(validity: .unreadable) }
        var facts = SignatureFacts(validity: validity(of: code))
        switch facts.validity {
        case .unsigned, .unreadable:
            return facts
        case .valid, .invalid:
            readSigningInformation(of: code, into: &facts)
        }
        guard facts.validity == .valid, !facts.isAdHoc else { return facts }

        facts.isIssuedByApple = satisfies(code, Requirement.issuedByApple)
        guard facts.isIssuedByApple else { return facts }
        facts.isApple = satisfies(code, Requirement.apple)
        facts.isAppStore = !facts.isApple && satisfies(code, Requirement.appStore)
        facts.isDeveloperID = !facts.isApple && !facts.isAppStore && satisfies(code, Requirement.developerID)
        facts.isNotarized = facts.isDeveloperID && satisfies(code, Requirement.notarized)
        return facts
    }

    /// Who signed the code and its cdhashes, `kSecCodeInfoUnique` first, or `nil` when it isn't
    /// signed: only signed code has a code directory to hash.
    public func identity(ofCodeAt url: URL) -> CodeIdentity? {
        guard let code = staticCode(at: url), let info = signingInformation(of: code) else { return nil }
        let unique = info[InfoKey.cdHash] as? Data
        let others = ((info[InfoKey.cdHashes] as? [Data]) ?? []).filter { $0 != unique }
        let cdHashes = [unique].compactMap { $0 } + others
        guard !cdHashes.isEmpty else { return nil }
        return CodeIdentity(teamID: info[InfoKey.teamID] as? String, cdHashes: cdHashes)
    }

    private func validity(of code: SecStaticCode) -> SignatureFacts.Validity {
        let status = SecStaticCodeCheckValidity(code, Self.validation, nil)
        switch status {
        case errSecSuccess:
            return .valid
        case errSecCSUnsigned:
            return .unsigned
        case errSecCSStaticCodeNotFound, errSecCSNoSuchCode, errSecCSInternalError:
            return .unreadable
        default:
            // Positive statuses are POSIX errors, such as a file that can't be opened.
            return status > 0 ? .unreadable : .invalid(status: status)
        }
    }

    private func staticCode(at url: URL) -> SecStaticCode? {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode) == errSecSuccess else { return nil }
        return staticCode
    }

    /// What the signature declares, without checking that the code matches it.
    private func signingInformation(of code: SecStaticCode) -> [String: Any]? {
        var information: CFDictionary?
        let flags = SecCSFlags(rawValue: UInt32(kSecCSSigningInformation))
        guard SecCodeCopySigningInformation(code, flags, &information) == errSecSuccess else { return nil }
        return information as? [String: Any]
    }

    private func readSigningInformation(of code: SecStaticCode, into facts: inout SignatureFacts) {
        guard let info = signingInformation(of: code) else { return }

        let signatureFlags = (info[InfoKey.flags] as? NSNumber)?.uint32Value ?? 0
        facts.isAdHoc = signatureFlags & SecCodeSignatureFlags.adhoc.rawValue != 0
        facts.teamID = info[InfoKey.teamID] as? String
        if let certificates = info[InfoKey.certificates] as? [SecCertificate], let leaf = certificates.first {
            facts.certificateSubject = SecCertificateCopySubjectSummary(leaf) as String?
        }
    }

    private func satisfies(_ code: SecStaticCode, _ text: String) -> Bool {
        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(text as CFString, [], &requirement) == errSecSuccess,
              let requirement
        else { return false }
        return SecStaticCodeCheckValidity(code, Self.requirementCheck, requirement) == errSecSuccess
    }
}
