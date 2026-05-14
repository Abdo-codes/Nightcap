import Foundation

struct WatchedApp: Codable, Equatable, Identifiable, Sendable {
    var bundleID: String
    var displayName: String

    var id: String { bundleID }
}

extension WatchedApp {
    static let ghostty = WatchedApp(
        bundleID: "com.mitchellh.ghostty",
        displayName: "Ghostty"
    )
}
