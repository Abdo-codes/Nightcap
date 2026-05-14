# Homebrew Distribution

Nightcap is available through the `Abdo-codes/tap` Homebrew tap. The first
public cask release is `0.1.0`, backed by a signed and notarized GitHub Release
asset.

The release workflow builds `Nightcap.app`, notarizes and staples it, publishes
`Nightcap-<version>.zip`, renders `nightcap.rb` with the zip's SHA-256, and
copies the cask into `Abdo-codes/homebrew-tap`.

## User install

```bash
brew install --cask Abdo-codes/tap/nightcap
```

If the cask is not fully qualified, users can tap first:

```bash
brew tap Abdo-codes/tap
brew install --cask nightcap
```

## Published locations

- Tap repository: <https://github.com/Abdo-codes/homebrew-tap>
- Cask file: <https://github.com/Abdo-codes/homebrew-tap/blob/main/Casks/nightcap.rb>
- First release: <https://github.com/Abdo-codes/Nightcap/releases/tag/v0.1.0>

## Maintainer automation

The public tap repository is `Abdo-codes/homebrew-tap`. Homebrew lets users
refer to that repository as `Abdo-codes/tap`.

The release workflow needs these secrets on the `Abdo-codes/Nightcap` GitHub
repository:

- `MACOS_CERTIFICATE_P12`: base64-encoded Developer ID Application `.p12`
- `MACOS_CERTIFICATE_PASSWORD`: password for the `.p12`
- `APPLE_ID`: Apple ID for notarization
- `APPLE_TEAM_ID`: Apple Developer team ID
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization
- `HOMEBREW_TAP_TOKEN`: token with contents write access to `Abdo-codes/homebrew-tap`

Configure this repository variable on `Abdo-codes/Nightcap`:

- `HOMEBREW_TAP_REPOSITORY`: `Abdo-codes/homebrew-tap`

The tap update is optional. If `HOMEBREW_TAP_REPOSITORY` or
`HOMEBREW_TAP_TOKEN` is missing, the release still publishes the zip and cask to
the GitHub Release; it just skips pushing the cask to the tap.

## Release flow

1. Update `MARKETING_VERSION` in `project.yml` to the release version.
2. Tag and push the release:

   ```bash
   git tag v<version>
   git push origin v<version>
   ```

3. The `Release` GitHub Actions workflow publishes:

   - `Nightcap-<version>.zip`
   - `nightcap.rb`

4. The workflow updates
   `Casks/nightcap.rb` in `Abdo-codes/homebrew-tap`.
5. Verify the tap:

   ```bash
   brew fetch --cask Abdo-codes/tap/nightcap
   ```

## Local dry run

Build a local package and cask:

```bash
scripts/package-release.sh <version>
```

For a packaging-only dry run without local signing:

```bash
CODE_SIGNING_ALLOWED=NO scripts/package-release.sh <version>
```

Unsigned dry-run artifacts are only for validating packaging. Homebrew users
should receive the Developer ID signed and notarized release produced by CI.
