import SwiftUI

extension ProtectionKind {
    /// Name of the protection as macOS calls it.
    var title: Text {
        switch self {
        case .fileVault:
            Text(verbatim: "FileVault")
        case .firewall:
            Text("Firewall", bundle: .module, comment: "Name of the macOS firewall in the security review.")
        case .gatekeeper:
            Text(verbatim: "Gatekeeper")
        case .systemIntegrityProtection:
            Text("System Integrity Protection", bundle: .module, comment: "Name of the macOS protection of system files in the security review.")
        case .automaticUpdates:
            Text("Automatic Security Updates", bundle: .module, comment: "Name of the Software Update options that install security fixes on their own, in the security review.")
        case .xprotect:
            Text(verbatim: "XProtect")
        }
    }
}

extension ProtectionState {
    var title: Text {
        switch self {
        case .on:
            Text("On", bundle: .module, comment: "Badge of a protection that is turned on.")
        case .off:
            Text("Off", bundle: .module, comment: "Badge of a protection that is turned off.")
        case .partial:
            Text("Partly On", bundle: .module, comment: "Badge of a protection with only some of its parts turned on.")
        case .outdated:
            Text("Out of Date", bundle: .module, comment: "Badge of XProtect when its definitions haven't been updated for months.")
        case .unknown:
            Text("Unknown", bundle: .module, comment: "Badge of a protection whose state the security review couldn't tell.")
        }
    }
}

extension ProtectionCheck {
    /// Why the state of the protection matters, in plain words.
    var explanation: Text {
        guard state != .unknown else {
            return Text("CleanMac couldn’t check how it’s set.", bundle: .module, comment: "Explanation of a protection whose state the security review couldn't tell.")
        }
        let isOn = state == .on
        switch kind {
        case .fileVault:
            return isOn
                ? Text("Your startup disk is encrypted: no one can read your files without your password, even by taking the disk out.", bundle: .module, comment: "Explanation of FileVault when it is on.")
                : Text("Your startup disk isn’t encrypted: someone who takes this Mac could read your files without your password.", bundle: .module, comment: "Explanation of FileVault when it is off.")
        case .firewall:
            return isOn
                ? Text("It blocks incoming connections you haven’t allowed.", bundle: .module, comment: "Explanation of the firewall when it is on.")
                : Text("Incoming connections reach any app or service that waits for them. It matters most on public Wi-Fi.", bundle: .module, comment: "Explanation of the firewall when it is off.")
        case .gatekeeper:
            return isOn
                ? Text("Only apps from the App Store and identified developers open without asking.", bundle: .module, comment: "Explanation of Gatekeeper when it is on.")
                : Text("Any app opens without being checked, even one that was tampered with.", bundle: .module, comment: "Explanation of Gatekeeper when it is off.")
        case .systemIntegrityProtection:
            return isOn
                ? Text("System files are protected from changes, even by apps with administrator rights.", bundle: .module, comment: "Explanation of System Integrity Protection when it is on.")
                : Text("All or part of it is off, so some system files can be changed. It’s usually turned off on purpose, such as to run macOS on an older Mac. Only macOS Recovery can turn it back on.", bundle: .module, comment: "Explanation of System Integrity Protection when it is off or partly off.")
        case .automaticUpdates:
            switch state {
            case .on:
                return Text("Security fixes and XProtect’s definitions install on their own.", bundle: .module, comment: "Explanation of automatic security updates when every option is on.")
            case .off:
                return Text("Updates aren’t checked for, so security fixes only arrive when you look for them.", bundle: .module, comment: "Explanation of automatic security updates when Software Update doesn't check for updates.")
            default:
                return Text("Some options are off, so security fixes may arrive late:", bundle: .module, comment: "Explanation of automatic security updates when some options are off. The options follow.")
            }
        case .xprotect:
            return isOn
                ? Text("macOS uses these definitions to block known malware.", bundle: .module, comment: "Explanation of XProtect when its definitions are recent.")
                : Text("Its definitions haven’t been updated for months, so recent malware may go unnoticed. Software Update installs them with its system files.", bundle: .module, comment: "Explanation of XProtect when its definitions haven't been updated for months.")
        }
    }
}

extension AutomaticUpdateOption {
    /// Name of the option, as Software Update's automatic update options describe it.
    var title: Text {
        switch self {
        case .checkForUpdates:
            Text("Check for updates", bundle: .module, comment: "Option of automatic updates in Software Update.")
        case .downloadUpdates:
            Text("Download new updates when available", bundle: .module, comment: "Option of automatic updates in Software Update.")
        case .installSecurityResponses:
            Text("Install Security Responses", bundle: .module, comment: "Option of automatic updates in Software Update that installs urgent security fixes.")
        case .installSystemDataFiles:
            Text("Install system data files", bundle: .module, comment: "Option of automatic updates in Software Update that installs data such as XProtect's definitions.")
        }
    }
}
