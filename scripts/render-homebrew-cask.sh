#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/render-homebrew-cask.sh <version> <sha256> [output-path]

Renders the Homebrew cask for a Nightcap GitHub Release asset.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 64
fi

version="$1"
sha256="$2"
output_path="${3:-dist/Casks/nightcap.rb}"

if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+){1,2}([.-][0-9A-Za-z]+)?$ ]]; then
  echo "error: version must look like 0.1.0, got '$version'" >&2
  exit 64
fi

if [[ ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "error: sha256 must be 64 lowercase hex characters" >&2
  exit 64
fi

mkdir -p "$(dirname "$output_path")"

cat >"$output_path" <<CASK
cask "nightcap" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/Abdo-codes/Nightcap/releases/download/v#{version}/Nightcap-#{version}.zip"
  name "Nightcap"
  desc "Keep your Mac awake while specific apps are running"
  homepage "https://github.com/Abdo-codes/Nightcap"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Nightcap.app"

  uninstall quit: "com.abdocodes.nightcap"

  zap trash: [
    "~/Library/Containers/com.abdocodes.nightcap",
    "~/Library/Preferences/com.abdocodes.nightcap.plist",
  ]
end
CASK

echo "Wrote $output_path"
