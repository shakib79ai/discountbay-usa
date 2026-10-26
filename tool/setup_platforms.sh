#!/usr/bin/env bash
# Creates the android/ and ios/ folders and applies DiscountBay settings
# (app name, permissions, release signing, icons, splash screen).
# Run once from the project root:  bash tool/setup_platforms.sh
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "Flutter is not installed or not on PATH."; exit 1; }

flutter create . --platforms=android,ios --org com.discountbay --project-name discountbay

# flutter create adds a counter-app test that doesn't apply to this app
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then rm test/widget_test.dart; fi

flutter pub get
python3 tool/patch_platforms.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create

echo
echo "Done. Next: flutter analyze && flutter test && flutter run"
