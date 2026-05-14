# Homebrew Distribution

Nightcap ships to Homebrew as a cask backed by signed GitHub Release assets.
The release workflow builds `Nightcap.app`, notarizes and staples it, publishes
`Nightcap-<version>.zip`, renders `nightcap.rb` with the zip's SHA-256, and can
copy the cask into a separate Homebrew tap repository.

## User install

After the tap is created and the first tagged release has run:

```bash
brew install --cask Abdo-codes/tap/nightcap
```

If the cask is not fully qualified, users can tap first:

```bash
brew tap Abdo-codes/tap
brew install --cask nightcap
```

## First-time maintainer setup

Create a public tap repository named `Abdo-codes/homebrew-tap`. Homebrew lets
users refer to that repository as `Abdo-codes/tap`.

Configure these secrets on the `Abdo-codes/Nightcap` GitHub repository:

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

1. Make sure `MARKETING_VERSION` in `project.yml` matches the tag version.
2. Tag and push the release:

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. The `Release` GitHub Actions workflow publishes:

   - `Nightcap-0.1.0.zip`
   - `nightcap.rb`

4. If the tap variables are configured, the workflow updates
   `Casks/nightcap.rb` in `Abdo-codes/homebrew-tap`.

## Local dry run

Build a local package and cask:

```bash
scripts/package-release.sh 0.1.0
```

For a packaging-only dry run without local signing:

```bash
CODE_SIGNING_ALLOWED=NO scripts/package-release.sh 0.1.0
```

Unsigned dry-run artifacts are only for validating packaging. Homebrew users
should receive the Developer ID signed and notarized release produced by CI.
