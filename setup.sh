#!/usr/bin/env bash
# Component 1 — walking skeleton setup
#
# Run from the root of your research-app repo:
#     bash setup.sh
#
# This does NOT hand-write the Flutter scaffold. It calls `flutter create`, which
# produces a known-good project for your exact Flutter version, then applies only
# the deltas Component 1 needs. Hand-written scaffolds drift from what the tool
# expects and fail in ways that are tedious to debug.

set -euo pipefail

APP_DIR="app"

echo "==> Flutter toolchain"
flutter --version
echo
echo "==> flutter doctor (read this; unresolved items here become build failures later)"
flutter doctor || true
echo

if [ -d "$APP_DIR" ]; then
  echo "!! $APP_DIR already exists. Delete it or edit APP_DIR in this script."
  exit 1
fi

echo "==> Creating scaffold"
flutter create \
  --org com.research.capture \
  --project-name questionnaire_capture \
  --platforms=android,ios \
  "$APP_DIR"

cd "$APP_DIR"

echo
echo "==> Adding dependencies"
# ML Kit is added at Component 1 deliberately, not later. It is the dependency
# that breaks iOS builds (armv7, deployment target). A skeleton without it would
# prove nothing about whether this project can produce an IPA.
flutter pub add google_mlkit_text_recognition
flutter pub add image
flutter pub add path_provider
flutter pub add shared_preferences

echo
echo "==> Android: minSdk 21 for ML Kit"
# ML Kit requires minSdkVersion 21+. Newer Flutter templates use a placeholder,
# so set it explicitly rather than relying on the default.
if grep -q "minSdk = flutter.minSdkVersion" android/app/build.gradle.kts 2>/dev/null; then
  sed -i '' 's/minSdk = flutter.minSdkVersion/minSdk = 21/' android/app/build.gradle.kts
  echo "   set minSdk = 21 in build.gradle.kts"
elif grep -q "minSdkVersion flutter.minSdkVersion" android/app/build.gradle 2>/dev/null; then
  sed -i '' 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 21/' android/app/build.gradle
  echo "   set minSdkVersion 21 in build.gradle"
else
  echo "   !! could not find the minSdk line — set it to 21 by hand"
fi

echo
echo "==> iOS: deployment target 15.5"
# google_ml_kit documents iOS 15.5 as the minimum platform.
if [ -f ios/Podfile ]; then
  sed -i '' "s/^# platform :ios.*/platform :ios, '15.5'/" ios/Podfile
  sed -i '' "s/^platform :ios.*/platform :ios, '15.5'/" ios/Podfile
  head -3 ios/Podfile
fi

echo
echo "==> Copying Component 1 source"
cp ../lib_main.dart lib/main.dart

echo
echo "==> Fetching packages"
flutter pub get

cat <<'NOTE'

============================================================
Scaffold ready. Remaining manual step for iOS:

  ML Kit does not support 32-bit architectures. Open
  ios/Runner.xcworkspace in Xcode and set:

      Runner > Build Settings > Excluded Architectures
        > Any iOS SDK  ->  armv7

  Without this, `flutter build ipa` fails.
  Source: https://pub.dev/packages/google_ml_kit

============================================================
Then, from the app/ directory:

  # Android — plug in a phone with USB debugging on
  flutter devices
  flutter run                       # confirm it launches
  flutter build apk --release       # -> build/app/outputs/flutter-apk/app-release.apk

  # iOS
  flutter build ipa                 # -> build/ios/ipa/

============================================================
NOTE
