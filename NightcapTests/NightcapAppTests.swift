import ComposableArchitecture
import ConcurrencyExtras
import Foundation
import XCTest
@testable import Nightcap

@MainActor
final class NightcapAppTests: XCTestCase {
    func test_launched_event_for_watched_app_triggers_acquire() async {
        let env = makeEnv(running: [])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.lifecycleEvent(.launched(bundleID: "com.mitchellh.ghostty"))) {
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
        }

        XCTAssertEqual(env.acquired.value, ["Nightcap: Ghostty"])
    }

    func test_terminate_event_releases_when_no_other_instances_running() async {
        let env = makeEnv(running: ["com.mitchellh.ghostty"])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
            $0.launchAtLoginStatus = .disabled
        }

        env.running.setValue([])
        await store.send(.lifecycleEvent(.terminated(bundleID: "com.mitchellh.ghostty"))) {
            $0.runningWatchedIDs = []
            $0.assertionHeld = false
        }

        XCTAssertGreaterThanOrEqual(env.released.value, 1)
    }

    func test_terminate_event_keeps_assertion_when_another_instance_still_running() async {
        let env = makeEnv(running: ["com.mitchellh.ghostty"])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.lifecycleEvent(.terminated(bundleID: "com.mitchellh.ghostty")))
    }

    func test_wake_event_reconciles_running_apps() async {
        let env = makeEnv(running: [])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.launchAtLoginStatus = .disabled
        }

        env.running.setValue(["com.mitchellh.ghostty"])
        await store.send(.lifecycleEvent(.wake)) {
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
        }

        env.running.setValue([])
        await store.send(.lifecycleEvent(.wake)) {
            $0.runningWatchedIDs = []
            $0.assertionHeld = false
        }
    }

    func test_duplicate_add_is_a_no_op() async {
        let env = makeEnv(running: [])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.launchAtLoginStatus = .disabled
        }

        let duplicate = WatchedApp(bundleID: "com.mitchellh.ghostty", displayName: "Ghostty")
        await store.send(.addAppRequested(duplicate))
    }

    func test_observation_toggle_off_releases_running_app_without_removing_it() async {
        let env = makeEnv(running: ["com.mitchellh.ghostty"])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.observationToggled("com.mitchellh.ghostty", false)) {
            $0.$watchedApps.withLock { $0[0].isObserved = false }
            $0.runningWatchedIDs = []
            $0.assertionHeld = false
        }

        XCTAssertGreaterThanOrEqual(env.released.value, 1)
    }

    func test_observation_toggle_on_acquires_if_app_is_running() async {
        let env = makeEnv(running: ["com.mitchellh.ghostty"])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.observationToggled("com.mitchellh.ghostty", false)) {
            $0.$watchedApps.withLock { $0[0].isObserved = false }
            $0.runningWatchedIDs = []
            $0.assertionHeld = false
        }

        await store.send(.observationToggled("com.mitchellh.ghostty", true)) {
            $0.$watchedApps.withLock { $0[0].isObserved = true }
            $0.runningWatchedIDs = ["com.mitchellh.ghostty"]
            $0.assertionHeld = true
        }

        XCTAssertEqual(env.acquired.value, ["Nightcap: Ghostty", "Nightcap: Ghostty"])
    }

    func test_unobserved_app_launch_does_not_acquire() async {
        let env = makeEnv(running: [])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.observationToggled("com.mitchellh.ghostty", false)) {
            $0.$watchedApps.withLock { $0[0].isObserved = false }
        }

        await store.send(.lifecycleEvent(.launched(bundleID: "com.mitchellh.ghostty")))
        XCTAssertEqual(env.acquired.value, [])
    }

    func test_legacy_watched_app_records_decode_as_observed() throws {
        let data = #"{"bundleID":"com.example.app","displayName":"Example"}"#
            .data(using: .utf8)!

        let app = try JSONDecoder().decode(WatchedApp.self, from: data)

        XCTAssertTrue(app.isObserved)
    }

    func test_launch_at_login_failure_rolls_back() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLifecycleClient.runningBundleIDs = { [] }
            $0.appLifecycleClient.events = { .finished }
            $0.launchAtLoginClient.status = { .disabled }
            $0.launchAtLoginClient.setEnabled = { _ in throw TestError.simulated }
            $0.powerAssertionClient.acquire = { _ in true }
            $0.powerAssertionClient.release = {}
        }

        await store.send(.onAppear) {
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.launchAtLoginToggled(true)) {
            $0.launchAtLoginStatus = .enabled
        }

        await store.receive(\.launchAtLoginStatusUpdated) {
            $0.launchAtLoginStatus = .disabled
        }
    }

    func test_quit_releases_assertion_before_terminate() async {
        let env = makeEnv(running: [])
        let store = makeStore(env: env)

        await store.send(.onAppear) {
            $0.launchAtLoginStatus = .disabled
        }

        await store.send(.quitTapped)
        XCTAssertGreaterThanOrEqual(env.released.value, 1)
    }

    // MARK: - Helpers

    private enum TestError: Error { case simulated }

    private struct TestEnv {
        let running: LockIsolated<Set<String>>
        let acquired: LockIsolated<[String]>
        let released: LockIsolated<Int>
    }

    private func makeEnv(running: Set<String>) -> TestEnv {
        TestEnv(
            running: LockIsolated(running),
            acquired: LockIsolated([]),
            released: LockIsolated(0)
        )
    }

    private func makeStore(
        env: TestEnv,
        acquireReturns: Bool = true
    ) -> TestStore<AppFeature.State, AppFeature.Action> {
        TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLifecycleClient.runningBundleIDs = { env.running.value }
            $0.appLifecycleClient.events = { .finished }
            $0.launchAtLoginClient.status = { .disabled }
            $0.powerAssertionClient.acquire = { reason in
                env.acquired.withValue { $0.append(reason) }
                return acquireReturns
            }
            $0.powerAssertionClient.release = {
                env.released.withValue { $0 += 1 }
            }
        }
    }
}
