# Contributing to Nightcap

Thanks for the interest. Nightcap is small enough that most contributions
turn around quickly — the test suite runs in seconds and the codebase is
under a thousand lines.

## Dev setup

Prerequisites:

- macOS 14.0 (Sonoma) or later
- Xcode 16 or later
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

Clone + open:

```bash
git clone https://github.com/Abdo-codes/Nightcap.git
cd Nightcap
xcodegen
open Nightcap.xcodeproj
```

The `.xcodeproj` is regenerated from `project.yml` and is **not** checked in.
Run `xcodegen` whenever you add a new source file.

## Building without an Apple Developer team

`project.yml` defaults to `DEVELOPMENT_TEAM: 85R85ZNGEX` (the original
author's team). To build locally without signing errors:

**Option A** — disable signing for local builds:

```bash
xcodebuild -project Nightcap.xcodeproj -scheme Nightcap \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

**Option B** — change the team in `project.yml` to your own, then re-run
`xcodegen`. Don't commit that change.

CI runs with `CODE_SIGNING_ALLOWED=NO` so you don't need to do anything special
for PRs.

## Tests

```bash
xcodebuild test -project Nightcap.xcodeproj -scheme Nightcap \
  -destination 'platform=macOS,arch=arm64'
```

CI runs the same command on every push and PR. PRs that break tests will be
blocked from merging.

If you add new behavior to `AppFeature` or any service client, add a
`TestStore`-based test in `NightcapTests/`.

## Code conventions

- **One exported type per Swift file.** Colocate tightly-coupled private
  helpers below the exported type.
- **`@DependencyClient` for all side effects.** Anything that touches IOKit,
  NSWorkspace, ServiceManagement, or AppKit gets wrapped in a client struct
  with `liveValue` and `testValue` implementations. See
  `Nightcap/Services/` for examples.
- **Reducer mutations stay in `Reduce { state, action in ... }`.** Effects
  go through `.run`. No side effects mid-mutation.
- **No comments explaining what code does.** If the code needs a comment to
  explain *what*, rename a variable instead. Comments are for *why* when the
  reason isn't obvious from the code or commit message.

## Pull request checklist

Before opening a PR:

1. `xcodegen` runs clean
2. `xcodebuild build` succeeds in both Debug and Release
3. `xcodebuild test` passes all tests
4. You've added tests for any new behavior in `AppFeature.swift`
5. If you touched IOKit or `NSWorkspace` code, you've verified the assertion
   shows correctly in `pmset -g assertions` after launching

PR title format: short and imperative — `Fix wake reconcile after lid close`,
not `Fixes for sleep`.

## Issue triage

- **Bug:** include macOS version, Nightcap version, steps to reproduce, and
  whether the issue is visible in `pmset -g assertions` output.
- **Feature:** describe the *use case* before the proposed solution.
  Nightcap's scope is narrow on purpose; not every reasonable feature fits.

## Out-of-scope contributions

To keep the App Store review and binary size sane, Nightcap will not accept:

- Network code (analytics, update checks, cloud sync, etc.)
- Third-party SDKs that aren't already in the dependency list
- Display-sleep prevention as a default (it's a battery-killer on laptops)
- Per-window or per-tab tracking (the bundle-ID level is the contract)

Open an issue first if you're unsure.
