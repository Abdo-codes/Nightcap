# Privacy Policy

**Last updated:** May 14, 2026

Nightcap collects nothing. This document exists because the Mac App Store
requires a public privacy policy URL — not because there's anything to
disclose.

## What we collect

**Nothing.** Nightcap does not collect, transmit, log, or share any user
data. There are no analytics, no telemetry, no crash reporting, no advertising
identifiers, no user accounts, and no network connections of any kind.

## What we store locally

Nightcap stores one file on your Mac:

- `~/Library/Containers/com.abdocodes.nightcap/Data/Documents/watched-apps.json`

This file contains a list of the apps you've chosen to watch (bundle ID and
display name). It never leaves your device. macOS isolates this file inside
the app's sandbox container, accessible only to Nightcap itself and to you.

## Required-reason API declarations

Nightcap declares the following required-reason API usage in its
[`PrivacyInfo.xcprivacy`](Nightcap/PrivacyInfo.xcprivacy) manifest, per Apple
policy:

| API | Reason code | Purpose |
| --- | --- | --- |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | Reading the app's own preferences (transitive use via SwiftUI / TCA). |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | Reading file metadata of the app's own container files (the `watched-apps.json` above). |

Neither category accesses user data — both are scoped to Nightcap's own
sandbox.

## Third-party SDKs

Nightcap statically links the following open-source Swift packages, all from
[Point-Free](https://github.com/pointfreeco):

- swift-composable-architecture
- swift-dependencies
- swift-sharing
- swift-case-paths
- swift-concurrency-extras
- swift-perception
- swift-custom-dump
- swift-identified-collections
- swift-navigation
- swift-clocks
- combine-schedulers
- xctest-dynamic-overlay

None of these SDKs perform analytics, networking, or data collection.

## Children

Nightcap is not directed at children. It contains no advertising and no data
collection of any kind, so it is safe for users of any age.

## Changes to this policy

If Nightcap ever starts collecting data, this document will be updated and
the version field in the Mac App Store listing will be bumped. The change
history is publicly visible in the
[git log](https://github.com/Abdo-codes/Nightcap/commits/main/PRIVACY.md) of
this repository.

## Contact

Questions or concerns: open an issue at
[github.com/Abdo-codes/Nightcap/issues](https://github.com/Abdo-codes/Nightcap/issues).
