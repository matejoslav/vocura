#!/usr/bin/env bash
#
# Build Vocura in Release and install it into /Applications.
# Usage:  ./scripts/install-app.sh
#
set -euo pipefail

APP_NAME="Vocura"
BUNDLE_ID="dev.matejoslav.vocura"
DERIVED="build/install-derived-data"

# Always run from the repo root (one level up from this script).
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen not found. Install it with: brew install xcodegen" >&2
  exit 1
fi

echo "==> Regenerating Xcode project"
xcodegen generate

echo "==> Building $APP_NAME (Release)"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  -destination 'generic/platform=macOS' \
  clean build

APP_PATH="$DERIVED/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: built app not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Quitting any running instance"
osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 1

echo "==> Installing to /Applications/$APP_NAME.app"
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_PATH" "/Applications/$APP_NAME.app"

# Clear the stale Accessibility grant for THIS app only (scoped by bundle id).
# Ad-hoc builds change signature each time, so the old grant points at a binary
# that no longer exists; resetting removes the orphan so you get one clean prompt
# instead of having to manually delete the old entry. Affects only $BUNDLE_ID.
echo "==> Resetting Accessibility permission for $BUNDLE_ID"
tccutil reset Accessibility "$BUNDLE_ID" || true

echo "==> Launching $APP_NAME"
open "/Applications/$APP_NAME.app"

echo "Done. $APP_NAME (Release) installed to /Applications and launched."
