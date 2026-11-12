import SwiftUI

/// When a launchd job runs, in words.
extension LaunchJobDefinition {
    var behavior: String {
        switch (runsAtLoad, keepsAlive) {
        case (true, true):
            String(localized: "Starts automatically and keeps running", bundle: .module, comment: "When a login item runs.")
        case (true, false):
            String(localized: "Starts automatically", bundle: .module, comment: "When a login item runs.")
        case (false, true):
            String(localized: "Keeps running", bundle: .module, comment: "When a login item runs.")
        case (false, false):
            String(localized: "Starts when needed", bundle: .module, comment: "When a login item runs: launchd starts it on demand.")
        }
    }
}
