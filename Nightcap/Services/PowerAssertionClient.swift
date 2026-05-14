import Dependencies
import DependenciesMacros
import Foundation
import IOKit
import IOKit.pwr_mgt
import os

@DependencyClient
struct PowerAssertionClient: Sendable {
    var acquire: @Sendable (_ reason: String) -> Bool = { _ in false }
    var release: @Sendable () -> Void
}

extension PowerAssertionClient: DependencyKey {
    static let liveValue: PowerAssertionClient = {
        let holder = AssertionHolder()
        return Self(
            acquire: { holder.acquire(reason: $0) },
            release: { holder.release() }
        )
    }()
}

extension DependencyValues {
    var powerAssertionClient: PowerAssertionClient {
        get { self[PowerAssertionClient.self] }
        set { self[PowerAssertionClient.self] = newValue }
    }
}

private let logger = Logger(subsystem: "com.abdocodes.nightcap", category: "PowerAssertion")

private final class AssertionHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var id: IOPMAssertionID = 0
    private var held = false

    func acquire(reason: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var newID: IOPMAssertionID = 0
        let createResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newID
        )
        guard createResult == kIOReturnSuccess else {
            logger.warning("IOPMAssertionCreateWithName failed (code \(createResult, privacy: .public))")
            return held
        }

        if held {
            let releaseResult = IOPMAssertionRelease(id)
            if releaseResult != kIOReturnSuccess {
                logger.warning("IOPMAssertionRelease (during swap) failed (code \(releaseResult, privacy: .public))")
            }
        }
        id = newID
        held = true
        return true
    }

    func release() {
        lock.lock()
        defer { lock.unlock() }
        guard held else { return }
        let result = IOPMAssertionRelease(id)
        if result != kIOReturnSuccess {
            logger.warning("IOPMAssertionRelease failed (code \(result, privacy: .public))")
        }
        held = false
        id = 0
    }
}
