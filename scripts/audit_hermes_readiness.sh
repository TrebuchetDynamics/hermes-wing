#!/usr/bin/env bash
set -euo pipefail

status=0
blockers=0

ok() { printf 'OK: %s\n' "$*"; }
info() { printf 'INFO: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; status=1; }
block() { printf 'BLOCKED: %s\n' "$*"; blockers=$((blockers + 1)); }

file_exists() {
  local path="$1" label="$2"
  if [ -e "$path" ]; then ok "$label ($path)"; else warn "$label missing ($path)"; fi
}

printf 'Navivox Hermes readiness audit (read-only)\n\n'

file_exists docs/runbooks/hermes-readiness-audit.md 'readiness audit doc'
file_exists docs/runbooks/hermes-platform-smoke.md 'platform smoke runbook'
file_exists docs/runbooks/android/live-mic-smoke.md 'Android live microphone runbook'
file_exists docs/runbooks/android/release-handoff.md 'Android release handoff runbook'
file_exists .github/workflows/hermes-platform-smoke.yml 'Hermes platform workflow file'
file_exists scripts/run_provider_hermes_smoke.sh 'provider smoke helper'
file_exists scripts/run_android_voice_smoke.sh 'Android speech readiness helper'
file_exists scripts/run_android_hermes_voice_loop_smoke.sh 'Android deterministic voice-loop helper'
file_exists scripts/prepare_android_live_mic_smoke.sh 'Android live mic prep helper'
file_exists scripts/record_android_live_mic_receipt.sh 'Android live mic receipt helper'
file_exists scripts/run_hermes_platform_workflow.sh 'platform workflow dispatch helper'

printf '\nLocal build artifacts (informational):\n'
[ -f build/web/main.dart.js ] && ok 'web e2e bundle present' || warn 'web e2e bundle not present; run flutter build web --release -t lib/main_e2e.dart'
if [ -f build/app/outputs/flutter-apk/app-debug.apk ]; then
  ok 'Android debug APK present'
  if command -v sha256sum >/dev/null 2>&1; then
    info "Android debug APK sha256: $(sha256sum build/app/outputs/flutter-apk/app-debug.apk | awk '{print $1}') (artifact identity only; not live Android or mic evidence)"
  fi
else
  warn 'Android debug APK not present; run flutter build apk --debug'
fi
[ -x build/linux/x64/release/bundle/navivox ] && ok 'Linux release binary present' || warn 'Linux release binary not present; run npm run linux:release-build'

printf '\nObjective checklist (read-only; not completion evidence):\n'
info 'provider-backed Hermes chat/voice: requires configured model/provider credentials plus a current npm run hermes:provider-smoke:local receipt; transcript voice is not physical mic/server audio'
info 'Android microphone + continuous voice: requires responsive audio-capable Android target and manual docs/runbooks/android/live-mic-smoke.md receipt'
info 'Windows, iOS, and macOS builds: require successful native-host runner jobs/artifacts or native host receipts'
info 'Hermes realtime/server audio: unimplemented; current voice path is local STT-to-text'
info 'Deferred Hermes surfaces: config admin, memory UI, jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media, files/context folders, and raw diagnostics/log export; multi-endpoint/profile management is implemented locally'

android_live_mic_receipt="${NAVIVOX_ANDROID_LIVE_MIC_RECEIPT:-build/receipts/android-live-mic-smoke.json}"
android_live_mic_receipt_valid=0
if [ -f "$android_live_mic_receipt" ]; then
  current_head_sha="$(git rev-parse HEAD 2>/dev/null || true)"
  if python3 - "$android_live_mic_receipt" "$current_head_sha" <<'PY'
import json, re, sys
from urllib.parse import urlsplit
SECRET_PATTERN = re.compile(
    r'(bearer\s+\S+|(?:api[-_ ]?key|token|secret)\s*(?:=|:)\s*\S+|secret[-_a-z0-9.]{4,}|sk-[a-z0-9_-]{12,})',
    re.IGNORECASE,
)
receipt = json.load(open(sys.argv[1], encoding='utf-8'))
current_head_sha = sys.argv[2]
missing = []
if receipt.get('status') != 'passed':
    missing.append('status=passed')
for key in ['timestamp_utc', 'head_sha', 'device_id', 'hermes_url', 'spoken_phrase', 'provider_reply_observed', 'second_spoken_phrase']:
    if not receipt.get(key):
        missing.append(key)
if current_head_sha and receipt.get('head_sha') != current_head_sha:
    missing.append('head_sha must match current git HEAD')
device_properties = receipt.get('device_properties') or {}
for key in ['manufacturer', 'model', 'sdk', 'fingerprint']:
    if not device_properties.get(key):
        missing.append(f'device_properties.{key}')
package_info = receipt.get('package_info') or {}
if package_info.get('package_name') != 'com.trebuchetdynamics.navivox':
    missing.append('package_info.package_name=com.trebuchetdynamics.navivox')
if package_info.get('installed') is not True:
    missing.append('package_info.installed=true')
if package_info.get('record_audio_granted') is not True:
    missing.append('package_info.record_audio_granted=true')
for key in ['version_name', 'version_code']:
    if not package_info.get(key):
        missing.append(f'package_info.{key}')
if not package_info.get('paths'):
    missing.append('package_info.paths')
for key in ['tts_observed', 'rearm_observed', 'no_secret_leaks_observed', 'distinct_rearmed_turn_observed', 'hermes_url_sanitized']:
    if receipt.get(key) is not True:
        missing.append(f'{key}=true')
hermes_url = str(receipt.get('hermes_url', ''))
parsed_hermes_url = urlsplit(hermes_url)
if parsed_hermes_url.username or parsed_hermes_url.password or parsed_hermes_url.query or parsed_hermes_url.fragment:
    missing.append('hermes_url must omit userinfo, query, and fragment')
if parsed_hermes_url.path not in ('', '/'):
    missing.append('hermes_url must be an origin without copied route/path state')
for key in ['spoken_phrase', 'provider_reply_observed', 'second_spoken_phrase']:
    value = str(receipt.get(key, ''))
    if len(value) > 240:
        missing.append(f'{key} must be 240 characters or less')
    if SECRET_PATTERN.search(value):
        missing.append(f'{key} must not contain secret-looking values')
spoken_phrase = str(receipt.get('spoken_phrase', '')).strip().casefold()
second_spoken_phrase = str(receipt.get('second_spoken_phrase', '')).strip().casefold()
provider_reply = str(receipt.get('provider_reply_observed', '')).strip().casefold()
if spoken_phrase == second_spoken_phrase:
    missing.append('second_spoken_phrase must differ from spoken_phrase')
if provider_reply in {spoken_phrase, second_spoken_phrase}:
    missing.append('provider_reply_observed must differ from spoken phrases')
evidence = set(receipt.get('evidence_for') or [])
for item in [
    'physical Android microphone audio to local STT',
    'Hermes text turn from spoken phrase',
    'provider-backed Hermes reply',
    'TTS playback and continuous voice re-arm',
    'distinct second spoken turn after re-arm',
]:
    if item not in evidence:
        missing.append(f'evidence_for:{item}')
not_evidence = set(receipt.get('not_evidence_for') or [])
for item in [
    'Hermes realtime/server audio',
    'Windows/iOS/macOS native-host receipts',
    'platform workflow publication',
    'deferred Hermes Desktop parity surfaces',
    'whole-goal completion',
]:
    if item not in not_evidence:
        missing.append(f'not_evidence_for:{item}')
if missing:
    print('; '.join(missing))
    sys.exit(1)
PY
  then
    android_live_mic_receipt_valid=1
    ok "Android live microphone receipt present ($android_live_mic_receipt)"
    info 'Android live mic receipt is not realtime/server-audio, native-host, workflow, deferred-surface, or whole-goal evidence'
  else
    block "Android live microphone receipt is present but incomplete ($android_live_mic_receipt); rerun npm run android:live-mic-receipt after manual smoke"
  fi
fi

platform_receipt="${NAVIVOX_PLATFORM_WORKFLOW_RECEIPT:-build/receipts/hermes-platform-workflow.json}"
platform_receipt_valid=0
if [ -f "$platform_receipt" ]; then
  current_head_sha="$(git rev-parse HEAD 2>/dev/null || true)"
  if python3 - "$platform_receipt" "$current_head_sha" <<'PY'
import json, sys
receipt = json.load(open(sys.argv[1], encoding='utf-8'))
current_head_sha = sys.argv[2]
missing = []
if receipt.get('status') != 'passed':
    missing.append('status=passed')
if receipt.get('workflow') != 'Hermes platform smoke':
    missing.append('workflow=Hermes platform smoke')
if receipt.get('run_status') != 'completed':
    missing.append('run_status=completed')
if receipt.get('conclusion') != 'success':
    missing.append('conclusion=success')
for key in ['timestamp_utc', 'run_id', 'url', 'head_sha']:
    if not receipt.get(key):
        missing.append(key)
if current_head_sha and receipt.get('head_sha') != current_head_sha:
    missing.append('head_sha must match current git HEAD')
if receipt.get('missing_required_artifacts') not in (None, []):
    missing.append('missing_required_artifacts must be empty')
if receipt.get('invalid_required_artifacts') not in (None, []):
    missing.append('invalid_required_artifacts must be empty')
if receipt.get('missing_required_jobs') not in (None, []):
    missing.append('missing_required_jobs must be empty')
if receipt.get('invalid_required_jobs') not in (None, []):
    missing.append('invalid_required_jobs must be empty')
artifacts = set(receipt.get('artifacts') or [])
artifact_details = receipt.get('artifact_details') or []
artifact_details_by_name = {
    artifact.get('name'): artifact
    for artifact in artifact_details
    if isinstance(artifact, dict)
}
for artifact in [
    'navivox-windows-debug-bundle',
    'navivox-ios-simulator-app',
    'navivox-macos-debug-app',
]:
    if artifact not in artifacts:
        missing.append(f'artifact:{artifact}')
    detail = artifact_details_by_name.get(artifact)
    if not detail:
        missing.append(f'artifact_details:{artifact}')
        continue
    if not detail.get('id'):
        missing.append(f'artifact_details:{artifact}:id')
    if int(detail.get('size_in_bytes') or 0) <= 0:
        missing.append(f'artifact_details:{artifact}:size_in_bytes>0')
    if detail.get('expired') is not False:
        missing.append(f'artifact_details:{artifact}:expired=false')
    if not detail.get('archive_download_url'):
        missing.append(f'artifact_details:{artifact}:archive_download_url')
job_details = receipt.get('job_details') or []
job_details_by_name = {
    job.get('name'): job
    for job in job_details
    if isinstance(job, dict)
}
for job_name in [
    'Windows desktop build',
    'iOS simulator build',
    'macOS desktop build',
]:
    detail = job_details_by_name.get(job_name)
    if not detail:
        missing.append(f'job_details:{job_name}')
        continue
    if detail.get('status') != 'completed':
        missing.append(f'job_details:{job_name}:status=completed')
    if detail.get('conclusion') != 'success':
        missing.append(f'job_details:{job_name}:conclusion=success')
evidence = set(receipt.get('evidence_for') or [])
for item in [
    'published Hermes platform workflow',
    'Windows desktop native-host build artifact',
    'iOS simulator native-host build artifact',
    'macOS desktop native-host build artifact',
]:
    if item not in evidence:
        missing.append(f'evidence_for:{item}')
not_evidence = set(receipt.get('not_evidence_for') or [])
for item in [
    'physical Android microphone audio',
    'Hermes realtime/server audio',
    'deferred Hermes Desktop parity surfaces',
    'whole-goal completion',
]:
    if item not in not_evidence:
        missing.append(f'not_evidence_for:{item}')
if missing:
    print('; '.join(missing))
    sys.exit(1)
PY
  then
    platform_receipt_valid=1
    ok "platform workflow/native-host receipt present ($platform_receipt)"
    info 'platform workflow receipt is not Android physical mic, realtime/server-audio, deferred-surface, or whole-goal evidence'
  else
    block "platform workflow receipt is present but incomplete ($platform_receipt); rerun npm run platform:workflow-smoke with NAVIVOX_WATCH_WORKFLOW=true after publishing the workflow"
  fi
fi

printf '\nExternal receipt blockers:\n'
if command -v gh >/dev/null 2>&1; then
  workflow_list="$(gh workflow list 2>&1 || true)"
  gh_auth_status="$(gh auth status 2>&1 || true)"
  if printf '%s\n' "$workflow_list" | grep -Fq 'Hermes platform smoke'; then
    ok 'Hermes platform workflow visible to gh'
  elif [ "$platform_receipt_valid" = 1 ]; then
    ok 'Hermes platform workflow publication is covered by the recorded successful workflow receipt'
  else
    block 'Hermes platform workflow is not visible to gh; publish the workflow then run npm run platform:workflow-smoke before claiming Windows/iOS/macOS/hosted Android receipts'
    printf 'INFO: Visible workflows (not native-host receipt evidence):\n'
    printf '%s\n' "$workflow_list" | sed 's/^/INFO:   /'
  fi
  if printf '%s\n' "$gh_auth_status" | grep -Fq "Token scopes:" && ! printf '%s\n' "$gh_auth_status" | grep -Fq "'workflow'"; then
    info 'active gh token scopes do not include workflow; publishing .github/workflows/hermes-platform-smoke.yml will remain blocked until credentials are refreshed'
  fi
else
  block 'gh not installed; cannot inspect/dispatch native-host workflow receipts; install gh before running npm run platform:workflow-smoke'
fi
info 'workflow dispatch without successful gh run view job/artifact evidence is not a platform receipt; NAVIVOX_WATCH_WORKFLOW=false only proves dispatch was requested'

if [ "$platform_receipt_valid" = 1 ]; then
  ok 'Windows desktop native-host build receipt recorded'
  ok 'iOS simulator native-host build receipt recorded'
  ok 'macOS desktop native-host build receipt recorded'
else
  block 'Windows desktop native-host build receipt missing; run on a Windows host or published platform workflow before claiming Windows readiness'
  block 'iOS simulator native-host build receipt missing; run on a macOS/Xcode host or published platform workflow before claiming iOS readiness'
  block 'macOS desktop native-host build receipt missing; run on a macOS/Xcode host or published platform workflow before claiming macOS readiness'
fi

if command -v adb >/dev/null 2>&1; then
  android_devices="$(adb devices | awk 'NR>1 && $2=="device" {print $1}' | paste -sd, -)"
  if [ -n "$android_devices" ]; then
    ok "Android target(s) online: $android_devices"
    if [ "$android_live_mic_receipt_valid" = 1 ]; then
      ok 'real spoken Android mic loop receipt recorded'
    else
      block 'real spoken Android mic loop still requires manual audio/provider evidence; online device alone is not a pass'
    fi
  else
    if [ "$android_live_mic_receipt_valid" = 1 ]; then
      ok 'real spoken Android mic loop receipt recorded; no current Android attachment required for this historical receipt'
    else
      block 'no online Android device/emulator for real spoken mic receipt; start an audio-capable target, follow docs/runbooks/android/live-mic-smoke.md, then run npm run android:live-mic-prep'
    fi
    if [ "$android_live_mic_receipt_valid" != 1 ]; then
      if command -v flutter >/dev/null 2>&1; then
        printf 'INFO: Flutter connected devices (not Android/audio receipt evidence):\n'
        flutter devices 2>/dev/null | sed 's/^/INFO:   /' || true
        printf 'INFO: Flutter emulator inventory (availability is not an online/audio receipt):\n'
        flutter emulators 2>/dev/null | sed 's/^/INFO:   /' || true
      fi
    fi
    emulator_bin="$(command -v emulator 2>/dev/null || true)"
    if [ -z "$emulator_bin" ] && [ -x /usr/lib/android-sdk/emulator/emulator ]; then
      emulator_bin=/usr/lib/android-sdk/emulator/emulator
    fi
    if [ -n "$emulator_bin" ]; then
      printf 'INFO: Android emulator acceleration check (not audio/live-mic evidence):\n'
      "$emulator_bin" -accel-check 2>&1 | sed 's/^/INFO:   /' || true
    fi
  fi
else
  block 'adb not installed; cannot inspect Android device readiness'
fi

if [ -f "${NAVIVOX_CONFIGURED_HERMES_HOME:-${HERMES_HOME:-$HOME/.hermes}}/config.yaml" ]; then
  info 'configured local Hermes home appears present; this is not a provider-smoke receipt, run npm run hermes:provider-smoke:local for proof'
else
  block 'no configured Hermes config.yaml found for local provider-backed smoke'
fi
provider_receipt="${NAVIVOX_PROVIDER_SMOKE_RECEIPT:-build/receipts/hermes-provider-smoke.json}"
if [ -f "$provider_receipt" ]; then
  if python3 - "$provider_receipt" <<'PY'
import json, sys
receipt = json.load(open(sys.argv[1], encoding='utf-8'))
missing = []
if receipt.get('status') != 'passed':
    missing.append('status=passed')
if receipt.get('coverage') != 'typed text plus deterministic transcript voice':
    missing.append('typed text plus deterministic transcript voice coverage')
if receipt.get('playwright_retries') != 0:
    missing.append('playwright_retries=0')
not_evidence = set(receipt.get('not_evidence_for') or [])
for item in [
    'physical Android microphone audio',
    'Hermes realtime/server audio',
    'native-host Windows/iOS/macOS receipts',
    'whole-goal completion',
]:
    if item not in not_evidence:
        missing.append(f'not_evidence_for:{item}')
if not receipt.get('timestamp_utc'):
    missing.append('timestamp_utc')
if missing:
    print('; '.join(missing))
    sys.exit(1)
PY
  then
    ok "provider-backed Hermes text/transcript-voice smoke receipt present ($provider_receipt)"
    info 'provider transcript voice receipt is not physical microphone/server audio evidence'
  else
    block "provider-backed Hermes smoke receipt is present but not a complete passing no-retry typed-text/transcript-voice receipt ($provider_receipt); rerun npm run hermes:provider-smoke:local"
  fi
else
  block 'full live provider-backed Hermes chat/voice smoke receipt missing from this audit; run npm run hermes:provider-smoke:local with configured model/provider credentials; deterministic transcript voice is not physical microphone/server audio evidence'
fi

block 'Hermes realtime/server audio remains unimplemented; local STT-to-text only'
block 'Hermes config editing/admin remains deferred by policy'
block 'Hermes memory UI remains deferred by policy'
block 'Hermes jobs/schedules admin remains deferred; current jobs support is read-only inventory only'
block 'Hermes messaging gateways remain deferred by policy'
block 'Hermes persona/SOUL editing remains deferred by policy'
block 'Hermes attachments/media remain deferred by policy'
block 'Hermes files/context folders remain deferred by policy'
block 'Hermes raw diagnostics/log export remains deferred; bounded diagnostics only'
ok 'Hermes multi-endpoint/profile management available locally with secure per-profile API-key storage'
printf '\nSummary: %s blocker(s), %s warning state.\n' "$blockers" "$status"
if [ "$blockers" -gt 0 ]; then
  printf 'Completion verdict: NOT COMPLETE; live provider/device/native-host or deferred-surface blockers remain.\n'
fi
printf 'This audit is informational and must not be used as a completion receipt by itself.\n'
printf 'Do not promote proxy evidence (tests, APK hashes, configured Hermes home, workflow YAML, or dispatch-only output) to completion.\n'

if [ "${NAVIVOX_FAIL_ON_BLOCKERS:-0}" = "1" ] && [ "$blockers" -gt 0 ]; then
  exit 3
fi
exit 0
