#!/usr/bin/env bash
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS requires macOS and Xcode." >&2
  exit 1
fi
: "${API_BASE_URL:?Set API_BASE_URL to the backend address; see README.md.}"
cd "$(dirname "$0")/../flutter_app"
flutter pub get
flutter run -d "${1:?Pass the iOS device or simulator ID from flutter devices}" --dart-define="API_BASE_URL=$API_BASE_URL"
