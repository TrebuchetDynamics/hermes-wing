#!/usr/bin/env bash
set -euo pipefail

for cmd in adb flutter python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required to record the Android live microphone receipt." >&2
    exit 1
  fi
done

require_env() {
  local name="$1"
  local value="${!name:-}"
  if [ -z "$value" ]; then
    echo "$name is required to record the Android live microphone receipt." >&2
    exit 2
  fi
}

require_true() {
  local name="$1"
  local value="${!name:-}"
  if [ "$value" != "true" ]; then
    echo "$name=true is required; do not record a receipt without that manual observation." >&2
    exit 2
  fi
}

require_env NAVIVOX_ANDROID_HERMES_URL
require_env NAVIVOX_ANDROID_SPOKEN_PHRASE
require_env NAVIVOX_ANDROID_PROVIDER_REPLY
require_env NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE
# Required manual-observation gates: NAVIVOX_ANDROID_TTS_OBSERVED=true,
# NAVIVOX_ANDROID_REARM_OBSERVED=true, NAVIVOX_ANDROID_NO_SECRET_LEAKS=true.
require_true NAVIVOX_ANDROID_TTS_OBSERVED
require_true NAVIVOX_ANDROID_REARM_OBSERVED
require_true NAVIVOX_ANDROID_NO_SECRET_LEAKS

package_name="${NAVIVOX_ANDROID_PACKAGE:-com.trebuchetdynamics.navivox}"

device="${NAVIVOX_ANDROID_DEVICE_ID:-}"
if [ -z "$device" ]; then
  device="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi
if [ -z "$device" ]; then
  echo "No online Android device/emulator found. Set NAVIVOX_ANDROID_DEVICE_ID after completing the manual smoke." >&2
  adb devices >&2 || true
  flutter devices >&2 || true
  exit 2
fi

if ! adb -s "$device" get-state >/dev/null 2>&1; then
  echo "Android target $device is not reachable via adb; cannot bind receipt to a device." >&2
  exit 2
fi

receipt_path="${NAVIVOX_ANDROID_LIVE_MIC_RECEIPT:-build/receipts/android-live-mic-smoke.json}"
mkdir -p "$(dirname "$receipt_path")"
python3 - "$receipt_path" <<'PY'
import datetime, json, os, re, subprocess, sys
from urllib.parse import urlsplit, urlunsplit

SECRET_PATTERN = re.compile(
    r'(bearer\s+\S+|(?:api[-_ ]?key|token|secret)\s*(?:=|:)\s*\S+|secret[-_a-z0-9.]{4,}|sk-[a-z0-9_-]{12,})',
    re.IGNORECASE,
)

path = sys.argv[1]
spoken_phrase = os.environ['NAVIVOX_ANDROID_SPOKEN_PHRASE'].strip()
second_spoken_phrase = os.environ['NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE'].strip()
provider_reply = os.environ['NAVIVOX_ANDROID_PROVIDER_REPLY'].strip()
if spoken_phrase.casefold() == second_spoken_phrase.casefold():
    raise SystemExit(
        'NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE must be a different observed turn after re-arm.'
    )
if provider_reply.casefold() in {spoken_phrase.casefold(), second_spoken_phrase.casefold()}:
    raise SystemExit(
        'NAVIVOX_ANDROID_PROVIDER_REPLY must be an observed assistant reply excerpt, not a repeated spoken phrase.'
    )
for label, value in {
    'NAVIVOX_ANDROID_SPOKEN_PHRASE': spoken_phrase,
    'NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE': second_spoken_phrase,
    'NAVIVOX_ANDROID_PROVIDER_REPLY': provider_reply,
}.items():
    if len(value) > 240:
        raise SystemExit(f'{label} is too long; record a short non-sensitive excerpt instead.')
    if SECRET_PATTERN.search(value):
        raise SystemExit(f'{label} appears to contain a secret; record a non-sensitive excerpt instead.')
device = os.environ.get('NAVIVOX_ANDROID_DEVICE_ID') or subprocess.check_output(
    ['adb', 'devices'], text=True
).splitlines()[1].split()[0]
try:
    head_sha = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], text=True, stderr=subprocess.DEVNULL
    ).strip()
except Exception:
    head_sha = ''

def adb_shell(*args):
    try:
        return subprocess.check_output(
            ['adb', '-s', device, 'shell', *args],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip().strip('\r')
    except Exception:
        return ''

def getprop(name):
    return adb_shell('getprop', name)

device_properties = {
    'manufacturer': getprop('ro.product.manufacturer'),
    'model': getprop('ro.product.model'),
    'sdk': getprop('ro.build.version.sdk'),
    'fingerprint': getprop('ro.build.fingerprint'),
}
package_name = os.environ.get('NAVIVOX_ANDROID_PACKAGE', 'com.trebuchetdynamics.navivox')
pm_path_output = adb_shell('pm', 'path', package_name)
package_dump = adb_shell('dumpsys', 'package', package_name)
version_name_match = re.search(r'versionName=([^\s]+)', package_dump)
version_code_match = re.search(r'versionCode=([^\s]+)', package_dump)
record_audio_granted = bool(
    re.search(
        r'android\.permission\.RECORD_AUDIO:\s+granted=true',
        package_dump,
        re.IGNORECASE,
    )
)
package_info = {
    'package_name': package_name,
    'installed': bool(pm_path_output),
    'paths': [line.removeprefix('package:') for line in pm_path_output.splitlines() if line],
    'version_name': version_name_match.group(1) if version_name_match else '',
    'version_code': version_code_match.group(1) if version_code_match else '',
    'record_audio_granted': record_audio_granted,
}
if not package_info['installed']:
    raise SystemExit(f'{package_name} is not installed on {device}; run npm run android:live-mic-prep first.')
if not package_info['record_audio_granted']:
    raise SystemExit(f'{package_name} does not have RECORD_AUDIO granted on {device}; run npm run android:live-mic-prep first.')

def sanitized_url(raw):
    parts = urlsplit(raw.strip())
    netloc = parts.netloc.rsplit('@', 1)[-1]
    return urlunsplit((parts.scheme, netloc, '', '', ''))

receipt = {
    'kind': 'android_live_mic_smoke',
    'status': 'passed',
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'head_sha': head_sha,
    'device_id': device,
    'device_properties': device_properties,
    'package_info': package_info,
    'hermes_url': sanitized_url(os.environ['NAVIVOX_ANDROID_HERMES_URL']),
    'hermes_url_sanitized': True,
    'spoken_phrase': spoken_phrase,
    'provider_reply_observed': provider_reply,
    'second_spoken_phrase': second_spoken_phrase,
    'tts_observed': os.environ['NAVIVOX_ANDROID_TTS_OBSERVED'] == 'true',
    'rearm_observed': os.environ['NAVIVOX_ANDROID_REARM_OBSERVED'] == 'true',
    'no_secret_leaks_observed': os.environ['NAVIVOX_ANDROID_NO_SECRET_LEAKS'] == 'true',
    'distinct_rearmed_turn_observed': True,
    'evidence_for': [
        'physical Android microphone audio to local STT',
        'Hermes text turn from spoken phrase',
        'provider-backed Hermes reply',
        'TTS playback and continuous voice re-arm',
        'distinct second spoken turn after re-arm',
    ],
    'not_evidence_for': [
        'Hermes realtime/server audio',
        'Windows/iOS/macOS native-host receipts',
        'platform workflow publication',
        'deferred Hermes Desktop parity surfaces',
        'whole-goal completion',
    ],
}
with open(path, 'w', encoding='utf-8') as fh:
    json.dump(receipt, fh, indent=2)
    fh.write('\n')
PY

cat <<EOF
Android live microphone receipt written: $receipt_path

This receipt is physical Android mic/provider/TTS/re-arm evidence only when the
manual observations are truthful. It is not Hermes realtime/server-audio,
native-host, platform-workflow, deferred-surface, or whole-goal completion
evidence by itself; it is not whole-goal completion evidence.

Run NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any
completion claim.
EOF
