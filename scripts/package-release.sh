#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/package-release.sh [version]

Builds Nightcap for release, optionally notarizes it, zips Nightcap.app, and
renders dist/Casks/nightcap.rb with the computed SHA-256.

Environment:
  NOTARIZE=1                         Submit and staple notarization before zipping.
  APPLE_ID                           Apple ID used by xcrun notarytool.
  APPLE_TEAM_ID                      Apple Developer team ID for signing/notary.
  APPLE_APP_SPECIFIC_PASSWORD        App-specific password for xcrun notarytool.
  CODE_SIGN_IDENTITY                 Signing identity, defaults to Developer ID Application.
  CODE_SIGNING_ALLOWED=NO            Build unsigned for local packaging dry runs only.
  ALLOW_VERSION_MISMATCH=1           Allow tag/version mismatch for local testing.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

project_version="$(awk '/MARKETING_VERSION:/ { print $2; exit }' project.yml)"
version="${1:-$project_version}"

if [[ -z "$project_version" ]]; then
  echo "error: could not read MARKETING_VERSION from project.yml" >&2
  exit 65
fi

if [[ "$version" != "$project_version" && "${ALLOW_VERSION_MISMATCH:-0}" != "1" ]]; then
  echo "error: release version '$version' does not match project.yml MARKETING_VERSION '$project_version'" >&2
  exit 65
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 69
fi

build_root="$repo_root/build/release"
archive_path="$build_root/Nightcap.xcarchive"
dist_root="$repo_root/dist"
zip_path="$dist_root/Nightcap-$version.zip"
notary_zip_path="$build_root/Nightcap-notary.zip"
cask_path="$dist_root/Casks/nightcap.rb"
app_path="$archive_path/Products/Applications/Nightcap.app"

mkdir -p "$build_root" "$dist_root"
rm -rf "$archive_path"
rm -f "$zip_path" "$notary_zip_path" "$cask_path"

xcodegen

archive_args=(
  archive
  -project Nightcap.xcodeproj
  -scheme Nightcap
  -configuration Release
  -destination "generic/platform=macOS"
  -archivePath "$archive_path"
  -skipMacroValidation
)

if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
  archive_args+=(
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY"
    OTHER_CODE_SIGN_FLAGS=--timestamp
  )
elif [[ "${NOTARIZE:-0}" == "1" ]]; then
  archive_args+=(
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="Developer ID Application"
    OTHER_CODE_SIGN_FLAGS=--timestamp
  )
fi

if [[ -n "${CODE_SIGNING_ALLOWED:-}" ]]; then
  archive_args+=(CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED")
fi

if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
  archive_args+=(DEVELOPMENT_TEAM="$APPLE_TEAM_ID")
fi

xcodebuild "${archive_args[@]}"

if [[ ! -d "$app_path" ]]; then
  echo "error: expected app bundle at $app_path" >&2
  exit 66
fi

if [[ "${NOTARIZE:-0}" == "1" ]]; then
  : "${APPLE_ID:?APPLE_ID is required when NOTARIZE=1}"
  : "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required when NOTARIZE=1}"
  : "${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD is required when NOTARIZE=1}"

  ditto -c -k --keepParent "$app_path" "$notary_zip_path"
  xcrun notarytool submit "$notary_zip_path" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$app_path"
fi

ditto -c -k --keepParent "$app_path" "$zip_path"
sha256="$(shasum -a 256 "$zip_path" | awk '{ print $1 }')"

scripts/render-homebrew-cask.sh "$version" "$sha256" "$cask_path"

cat <<EOF
Release package ready:
  Zip:    $zip_path
  SHA256: $sha256
  Cask:   $cask_path
EOF
