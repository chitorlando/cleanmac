import SwiftUI

extension PrivacyPermission {
    /// Name of the permission as Privacy & Security calls it.
    var title: Text {
        switch self {
        case .fullDiskAccess:
            Text("Full Disk Access", bundle: .module, comment: "Name of the macOS permission that lets an app read every file.")
        case .screenRecording:
            Text("Screen Recording", bundle: .module, comment: "Name of the macOS permission that lets an app see the screen.")
        case .accessibility:
            Text("Accessibility", bundle: .module, comment: "Name of the macOS permission that lets an app control the Mac.")
        case .inputMonitoring:
            Text("Input Monitoring", bundle: .module, comment: "Name of the macOS permission that lets an app read the keyboard and mouse.")
        case .camera:
            Text("Camera", bundle: .module, comment: "Name of the macOS permission that lets an app use the camera.")
        case .microphone:
            Text("Microphone", bundle: .module, comment: "Name of the macOS permission that lets an app use the microphone.")
        }
    }

    /// What the permission lets an app do, in plain words.
    var explanation: Text {
        switch self {
        case .fullDiskAccess:
            Text("Can read all your files, including Mail, Messages and Safari’s.", bundle: .module, comment: "What Full Disk Access lets an app do.")
        case .screenRecording:
            Text("Can see everything on your screen.", bundle: .module, comment: "What Screen Recording lets an app do.")
        case .accessibility:
            Text("Can control your Mac and other apps.", bundle: .module, comment: "What Accessibility lets an app do.")
        case .inputMonitoring:
            Text("Can read what you type, even in other apps.", bundle: .module, comment: "What Input Monitoring lets an app do.")
        case .camera:
            Text("Can use the camera.", bundle: .module, comment: "What the Camera permission lets an app do.")
        case .microphone:
            Text("Can use the microphone.", bundle: .module, comment: "What the Microphone permission lets an app do.")
        }
    }
}
