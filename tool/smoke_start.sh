#!/usr/bin/env bash
# Installs an APK on the running emulator, cold-starts Focus and fails if it
# crashes on start (#281). Writes smoke.txt for the CI comment.
set -u
APK=${1:-build/app/outputs/flutter-apk/app-release.apk}
PKG=de.maestrodev.focus_timer
adb install -r "$APK" || { echo "install failed" > smoke.txt; exit 1; }
adb logcat -c
adb shell am start -W -n "$PKG/.MainActivity"
sleep 25
adb logcat -d -v time > logcat.txt
grep -E "Unhandled Exception|FATAL EXCEPTION|E/flutter|AndroidRuntime" logcat.txt | cut -c1-300 | head -60 > smoke.txt
if ! adb shell pidof "$PKG" > /dev/null; then
  echo "Focus is not running after the start." >> smoke.txt
fi
if [ -s smoke.txt ]; then
  cat smoke.txt
  exit 1
fi
echo "Focus started cleanly."
