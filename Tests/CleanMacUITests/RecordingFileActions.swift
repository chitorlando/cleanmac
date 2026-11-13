import CleanMacUI
import Foundation

/// Records the file actions it's asked for instead of touching Finder, apps or the pasteboard.
@MainActor
final class RecordingFileActions: FileActionPerforming {
    enum Call: Equatable {
        case showInFinder(URL)
        case open(URL)
        case copyPath(URL)
    }

    private(set) var calls: [Call] = []

    func showInFinder(_ url: URL) { calls.append(.showInFinder(url)) }
    func open(_ url: URL) { calls.append(.open(url)) }
    func copyPath(of url: URL) { calls.append(.copyPath(url)) }
}
