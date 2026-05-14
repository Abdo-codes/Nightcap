import AppKit
import Dependencies
import DependenciesMacros

@DependencyClient
struct AppQuitterClient: Sendable {
    var quit: @Sendable () -> Void
}

extension AppQuitterClient: DependencyKey {
    static let liveValue: AppQuitterClient = .init(
        quit: {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    )

    static let testValue = AppQuitterClient(quit: {})
}

extension DependencyValues {
    var appQuitterClient: AppQuitterClient {
        get { self[AppQuitterClient.self] }
        set { self[AppQuitterClient.self] = newValue }
    }
}
