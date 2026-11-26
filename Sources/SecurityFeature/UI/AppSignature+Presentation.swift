import SwiftUI

extension AppSignature {
    /// Badge of an app whose signature needs a look.
    var title: Text {
        switch self {
        case .rejectedByGatekeeper:
            Text("Blocked by Gatekeeper", bundle: .module, comment: "Badge of an app that is signed but that Gatekeeper wouldn't let open.")
        case .adHocOrSelfSigned:
            Text("Unverified Developer", bundle: .module, comment: "Badge of an app signed without a certificate from Apple.")
        case .unsigned:
            Text("Unsigned", bundle: .module, comment: "Badge of an app or a program without a code signature.")
        case .damaged:
            Text("Damaged Signature", bundle: .module, comment: "Badge of an app or a program whose files no longer match its code signature.")
        case .apple, .appStore, .notarized, .identifiedDeveloper, .unknown:
            Text("Signed", bundle: .module, comment: "Badge of an app with a trusted code signature.")
        }
    }

    /// Why the signature matters and what to do about it, in plain words.
    var explanation: Text {
        switch self {
        case .rejectedByGatekeeper:
            Text("It’s signed by an identified developer, but Gatekeeper wouldn’t open it: Apple hasn’t checked it for malware, or its certificate was revoked.", bundle: .module, comment: "Explanation of an app that Gatekeeper wouldn't let open.")
        case .adHocOrSelfSigned:
            Text("It’s signed, but not with a certificate from Apple, so nothing confirms who made it. That’s common for apps built by hand or installed from source. Keep it if you trust where it came from.", bundle: .module, comment: "Explanation of an app signed without a certificate from Apple.")
        case .unsigned:
            Text("It has no signature, so nothing confirms who made it or that it wasn’t changed. Keep it if you trust where it came from.", bundle: .module, comment: "Explanation of an app without a code signature.")
        case .damaged:
            Text("Its files no longer match its signature: something changed them after it was signed. Reinstalling it from its developer usually fixes that.", bundle: .module, comment: "Explanation of an app whose files no longer match its code signature.")
        case .apple, .appStore, .notarized, .identifiedDeveloper, .unknown:
            Text("Its signature is intact.", bundle: .module, comment: "Explanation of an app with a trusted code signature.")
        }
    }
}
