import Dependencies
import DependenciesMacros
import ServiceManagement

@DependencyClient
struct LaunchAtLoginClient: Sendable {
    var status: @Sendable () -> LaunchAtLoginStatus = { .unknown }
    var setEnabled: @Sendable (Bool) throws -> Void
}

extension LaunchAtLoginClient: DependencyKey {
    static let liveValue: LaunchAtLoginClient = .init(
        status: { LaunchAtLoginStatus(SMAppService.mainApp.status) },
        setEnabled: { enable in
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        }
    )
}

extension DependencyValues {
    var launchAtLoginClient: LaunchAtLoginClient {
        get { self[LaunchAtLoginClient.self] }
        set { self[LaunchAtLoginClient.self] = newValue }
    }
}
