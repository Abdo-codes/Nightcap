import Foundation

struct WatchedApp: Codable, Equatable, Identifiable, Sendable {
    var bundleID: String
    var displayName: String
    var isObserved: Bool

    init(bundleID: String, displayName: String, isObserved: Bool = true) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.isObserved = isObserved
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bundleID = try container.decode(String.self, forKey: .bundleID)
        displayName = try container.decode(String.self, forKey: .displayName)
        isObserved = try container.decodeIfPresent(Bool.self, forKey: .isObserved) ?? true
    }

    var id: String { bundleID }
}

extension WatchedApp {
    static let ghostty = WatchedApp(
        bundleID: "com.mitchellh.ghostty",
        displayName: "Ghostty"
    )
}
