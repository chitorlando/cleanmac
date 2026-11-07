import CleanMacCore
import Foundation

/// Leftovers attributed to more than one installed app, such as the data of two copies
/// of the same app. Removing them for one app would also remove them for the other.
public struct SharedLeftovers: Equatable, Sendable {
    private let urls: Set<URL>

    public init(apps: [InstalledApp]) {
        var owners: [URL: Int] = [:]
        for leftover in apps.flatMap(\.leftovers) {
            owners[leftover.item.url, default: 0] += 1
        }
        urls = Set(owners.filter { $0.value > 1 }.keys)
    }

    public static let none = SharedLeftovers(apps: [])

    public func contains(_ item: CleanableItem) -> Bool {
        urls.contains(item.url)
    }

    public func sharedLeftovers(of app: InstalledApp) -> [Leftover] {
        app.leftovers.filter { contains($0.item) }
    }
}
