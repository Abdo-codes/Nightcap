import AppKit
import Dependencies
import DependenciesMacros

@DependencyClient
struct AppLifecycleClient: Sendable {
    var runningBundleIDs: @Sendable () -> Set<String> = { [] }
    var events: @Sendable () -> AsyncStream<Event> = { .finished }

    enum Event: Sendable, Equatable {
        case launched(bundleID: String)
        case terminated(bundleID: String)
        case wake
    }
}

extension AppLifecycleClient: DependencyKey {
    static let liveValue: AppLifecycleClient = .init(
        runningBundleIDs: {
            Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        },
        events: {
            AsyncStream { continuation in
                let center = NSWorkspace.shared.notificationCenter
                let launchToken = center.addObserver(
                    forName: NSWorkspace.didLaunchApplicationNotification,
                    object: nil,
                    queue: .main
                ) { note in
                    guard
                        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                        let bundleID = app.bundleIdentifier
                    else { return }
                    continuation.yield(.launched(bundleID: bundleID))
                }
                let terminateToken = center.addObserver(
                    forName: NSWorkspace.didTerminateApplicationNotification,
                    object: nil,
                    queue: .main
                ) { note in
                    guard
                        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                        let bundleID = app.bundleIdentifier
                    else { return }
                    continuation.yield(.terminated(bundleID: bundleID))
                }
                let wakeToken = center.addObserver(
                    forName: NSWorkspace.didWakeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    continuation.yield(.wake)
                }
                continuation.onTermination = { _ in
                    center.removeObserver(launchToken)
                    center.removeObserver(terminateToken)
                    center.removeObserver(wakeToken)
                }
            }
        }
    )

    static let testValue = AppLifecycleClient()
}

extension DependencyValues {
    var appLifecycleClient: AppLifecycleClient {
        get { self[AppLifecycleClient.self] }
        set { self[AppLifecycleClient.self] = newValue }
    }
}
