# Changelog

All notable changes to Nightcap are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-14

### Added
- Menu-bar app that prevents idle system sleep while user-selected apps run
- Per-app watch list with persistence via `@Shared(.fileStorage)`
- Atomic-swap `IOPMAssertion` lifecycle — no sleep-gap during reason refresh
- `NSWorkspace.didWakeNotification` reconciliation — handles sleep/wake cycles
- Multi-instance terminate handling — assertion stays held while any instance runs
- Launch-at-login via `SMAppService.mainApp` with error rollback on failure
- "Approve in System Settings" affordance when login item requires approval
- Submenu Remove pattern (no more accidental tap-to-remove)
- 7 unit tests covering launch / terminate / wake / multi-instance / duplicate /
  rollback / quit paths
- `PrivacyInfo.xcprivacy` declaring zero data collection and required-reason
  API categories (UserDefaults `CA92.1`, file timestamp `C617.1`)
- Full sandbox + hardened runtime (Release configuration)

[Unreleased]: https://github.com/Abdo-codes/Nightcap/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Abdo-codes/Nightcap/releases/tag/v0.1.0
