import Foundation

public extension PrivacyPermission {
    /// Link that opens the pane of Privacy & Security that lists the apps allowed the permission.
    var settingsURL: URL? {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?\(settingsAnchor)")
    }

    private var settingsAnchor: String {
        switch self {
        case .fullDiskAccess: "Privacy_AllFiles"
        case .screenRecording: "Privacy_ScreenCapture"
        case .accessibility: "Privacy_Accessibility"
        case .inputMonitoring: "Privacy_ListenEvent"
        case .camera: "Privacy_Camera"
        case .microphone: "Privacy_Microphone"
        }
    }
}
