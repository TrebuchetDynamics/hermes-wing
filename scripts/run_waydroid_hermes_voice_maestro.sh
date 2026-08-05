#!/usr/bin/env bash
set -euo pipefail

for cmd in adb flutter maestro; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$cmd is required for the Waydroid voice smoke." >&2
    exit 1
  }
done

device="${WING_ANDROID_DEVICE_ID:-}"
if [ -z "$device" ]; then
  while read -r candidate state _; do
    if [ "$state" = device ] && \
      [ "$(adb -s "$candidate" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')" = Waydroid ]; then
      device="$candidate"
      break
    fi
  done < <(adb devices -l | tail -n +2)
fi
if [ -z "$device" ] || \
  [ "$(adb -s "$device" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')" != Waydroid ]; then
  echo "An online Waydroid target is required. Set WING_ANDROID_DEVICE_ID." >&2
  exit 2
fi

package="com.trebuchetdynamics.hermes.wing"
fixture_package="$package.voicefixture"
recognizer="$fixture_package/.HeadlessSpeechRecognitionService"
tts="$fixture_package/.HeadlessTextToSpeechService"
previous_recognizer="$(adb -s "$device" shell settings get secure voice_recognition_service | tr -d '\r')"
previous_tts="$(adb -s "$device" shell settings get secure tts_default_synth | tr -d '\r')"

restore_setting() {
  local key="$1" value="$2"
  if [ -z "$value" ] || [ "$value" = null ]; then
    adb -s "$device" shell settings delete secure "$key" >/dev/null 2>&1 || true
  else
    adb -s "$device" shell settings put secure "$key" "$value" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  restore_setting voice_recognition_service "$previous_recognizer"
  restore_setting tts_default_synth "$previous_tts"
  adb -s "$device" uninstall "$fixture_package" >/dev/null 2>&1 || true
}
trap cleanup EXIT

maestro check-syntax .maestro/hermes-continuous-voice-smoke.yaml
flutter build apk --debug \
  --target integration_test/hermes_continuous_voice_maestro_main.dart
./android/gradlew -p android :headless_voice_fixture:assembleDebug
adb -s "$device" install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s "$device" uninstall "$fixture_package" >/dev/null 2>&1 || true
adb -s "$device" install \
  build/headless_voice_fixture/outputs/apk/debug/headless_voice_fixture-debug.apk
adb -s "$device" shell settings put secure voice_recognition_service "$recognizer"
adb -s "$device" shell settings put secure tts_default_synth "$fixture_package"
adb -s "$device" shell pm clear "$package" >/dev/null
for voice_package in "$package" "$fixture_package"; do
  adb -s "$device" shell pm grant "$voice_package" android.permission.RECORD_AUDIO
done

printf 'Waydroid target: %s\n' "$device"
adb -s "$device" shell cmd package query-services \
  -a android.speech.RecognitionService
adb -s "$device" shell cmd package query-services \
  -a android.intent.action.TTS_SERVICE
maestro --device "$device" test .maestro/hermes-continuous-voice-smoke.yaml
