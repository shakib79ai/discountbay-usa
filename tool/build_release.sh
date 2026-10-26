#!/usr/bin/env bash
# Store builds (live API, demo data off).
#   bash tool/build_release.sh android   # → build/app/outputs/bundle/release/app-release.aab  (Google Play)
#   bash tool/build_release.sh ios       # → build/ios/ipa/*.ipa                               (App Store, macOS + Xcode)
#   API_BASE=https://api.discountbay.com bash tool/build_release.sh android
#
# --obfuscate makes the Dart code harder to read; keep build/symbols/<platform> for each version
# to decode crash stack traces.
set -euo pipefail
cd "$(dirname "$0")/.."
PLATFORM=${1:?usage: bash tool/build_release.sh android|ios}
API=${API_BASE:-https://api.discountbay.com}
SITE=${SITE_URL:-https://discountbay.com}
case "$API" in https://*) ;; *) echo "API_BASE must be https:// for store builds (got $API)"; exit 1;; esac

VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
echo "DiscountBay $VERSION → $API (live data)"
flutter pub get
flutter analyze --no-fatal-infos
flutter test

DEFINES=(--dart-define=DEMO=false --dart-define=API_BASE="$API" --dart-define=SITE_URL="$SITE")
case "$PLATFORM" in
  android)
    [ -f android/key.properties ] || { echo "android/key.properties missing — see docs/RELEASE.md, step A2 (release builds must use the upload key)"; exit 1; }
    flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android "${DEFINES[@]}"
    echo "✓ build/app/outputs/bundle/release/app-release.aab — upload in Play Console (Internal testing first)"
    ;;
  ios)
    flutter build ipa --release --obfuscate --split-debug-info=build/symbols/ios "${DEFINES[@]}"
    echo "✓ build/ios/ipa/ — upload with Transporter or Xcode Organizer, then test in TestFlight"
    ;;
  *) echo "unknown platform: $PLATFORM"; exit 1 ;;
esac
