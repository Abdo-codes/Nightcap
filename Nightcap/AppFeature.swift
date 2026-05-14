import AppKit
import ComposableArchitecture
import Foundation
import Sharing

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.fileStorage(.documentsDirectory.appending(component: "watched-apps.json")))
        var watchedApps: [WatchedApp] = [.ghostty]
        var runningWatchedIDs: Set<String> = []
        var launchAtLoginStatus: LaunchAtLoginStatus = .unknown
        var assertionHeld = false
    }

    enum Action {
        case onAppear
        case lifecycleEvent(AppLifecycleClient.Event)
        case reconcile
        case addAppRequested(WatchedApp)
        case removeAppRequested(WatchedApp.ID)
        case launchAtLoginToggled(Bool)
        case launchAtLoginStatusUpdated(LaunchAtLoginStatus)
        case quitTapped
    }

    private enum CancelID { case lifecycle, launchAtLogin }

    @Dependency(\.appLifecycleClient) var lifecycle
    @Dependency(\.powerAssertionClient) var assertion
    @Dependency(\.launchAtLoginClient) var launchAtLogin
    @Dependency(\.appQuitterClient) var quitter

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.launchAtLoginStatus = launchAtLogin.status()
                reconcileRunning(&state)
                return .run { send in
                    for await event in lifecycle.events() {
                        await send(.lifecycleEvent(event))
                    }
                }
                .cancellable(id: CancelID.lifecycle, cancelInFlight: true)

            case let .lifecycleEvent(.launched(id)):
                guard state.watchedApps.contains(where: { $0.bundleID == id }) else { return .none }
                state.runningWatchedIDs.insert(id)
                syncAssertion(&state)
                return .none

            case let .lifecycleEvent(.terminated(id)):
                guard state.runningWatchedIDs.contains(id) else { return .none }
                if !lifecycle.runningBundleIDs().contains(id) {
                    state.runningWatchedIDs.remove(id)
                    syncAssertion(&state)
                }
                return .none

            case .lifecycleEvent(.wake), .reconcile:
                reconcileRunning(&state)
                return .none

            case let .addAppRequested(app):
                if !state.watchedApps.contains(where: { $0.bundleID == app.bundleID }) {
                    state.$watchedApps.withLock { $0.append(app) }
                }
                if lifecycle.runningBundleIDs().contains(app.bundleID) {
                    state.runningWatchedIDs.insert(app.bundleID)
                    syncAssertion(&state)
                }
                return .none

            case let .removeAppRequested(id):
                state.$watchedApps.withLock { $0.removeAll { $0.bundleID == id } }
                if state.runningWatchedIDs.remove(id) != nil {
                    syncAssertion(&state)
                }
                return .none

            case let .launchAtLoginToggled(enable):
                let previous = state.launchAtLoginStatus
                state.launchAtLoginStatus = enable ? .enabled : .disabled
                return .run { send in
                    do {
                        try launchAtLogin.setEnabled(enable)
                        let actual = launchAtLogin.status()
                        let resolved: LaunchAtLoginStatus
                        switch actual {
                        case .enabled, .disabled, .requiresApproval:
                            resolved = actual
                        case .unknown, .error:
                            resolved = enable ? .enabled : .disabled
                        }
                        await send(.launchAtLoginStatusUpdated(resolved))
                    } catch {
                        await send(.launchAtLoginStatusUpdated(previous))
                    }
                }
                .cancellable(id: CancelID.launchAtLogin, cancelInFlight: true)

            case let .launchAtLoginStatusUpdated(status):
                state.launchAtLoginStatus = status
                return .none

            case .quitTapped:
                assertion.release()
                state.assertionHeld = false
                quitter.quit()
                return .none
            }
        }
    }

    private func reconcileRunning(_ state: inout State) {
        let watchedIDs = Set(state.watchedApps.map(\.bundleID))
        state.runningWatchedIDs = lifecycle.runningBundleIDs().intersection(watchedIDs)
        syncAssertion(&state)
    }

    private func syncAssertion(_ state: inout State) {
        if state.runningWatchedIDs.isEmpty {
            assertion.release()
            state.assertionHeld = false
        } else {
            let names = state.watchedApps
                .filter { state.runningWatchedIDs.contains($0.bundleID) }
                .map(\.displayName)
                .joined(separator: ", ")
            state.assertionHeld = assertion.acquire("Nightcap: \(names)")
        }
    }
}
