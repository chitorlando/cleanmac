import Darwin
import Foundation

/// `GatekeeperAssessing` that asks the system's policy daemon, as
/// `spctl --assess --type execute` does.
///
/// The Security framework exports `SecAssessmentCreate`, but the SDK has no header for it, so
/// it's looked up when needed. Without it, or when Gatekeeper can't assess the app, such as
/// one whose signature is damaged, the verdict is unavailable.
public struct SystemPolicyGatekeeper: GatekeeperAssessing {
    private typealias CreateAssessment = @convention(c) (
        CFURL, UInt64, CFDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>?
    ) -> Unmanaged<CFTypeRef>?
    private typealias CopyResult = @convention(c) (
        CFTypeRef, UInt64, UnsafeMutablePointer<Unmanaged<CFError>?>?
    ) -> Unmanaged<CFDictionary>?

    private static let securityFramework = "/System/Library/Frameworks/Security.framework/Security"

    /// The values of `kSecAssessmentContextKeyOperation`, `kSecAssessmentOperationTypeExecute`
    /// and `kSecAssessmentAssessmentVerdict`.
    private enum Key {
        static let operation = "operation"
        static let execute = "operation:execute"
        static let verdict = "assessment:verdict"
    }

    /// `kSecAssessmentDefaultFlags`.
    private static let defaultFlags: UInt64 = 0

    public init() {}

    public func verdict(forAppAt url: URL) -> GatekeeperVerdict {
        guard let framework = dlopen(Self.securityFramework, RTLD_LAZY) else { return .unavailable }
        defer { dlclose(framework) }
        guard let createSymbol = dlsym(framework, "SecAssessmentCreate"),
              let copyResultSymbol = dlsym(framework, "SecAssessmentCopyResult")
        else { return .unavailable }
        let create = unsafeBitCast(createSymbol, to: CreateAssessment.self)
        let copyResult = unsafeBitCast(copyResultSymbol, to: CopyResult.self)

        let context = [Key.operation: Key.execute] as CFDictionary
        guard let assessment = create(url as CFURL, Self.defaultFlags, context, nil)?.takeRetainedValue(),
              let result = copyResult(assessment, Self.defaultFlags, nil)?.takeRetainedValue() as? [String: Any],
              let isAccepted = result[Key.verdict] as? Bool
        else { return .unavailable }
        return isAccepted ? .accepted : .rejected
    }
}
