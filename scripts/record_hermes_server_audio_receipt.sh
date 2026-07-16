#!/usr/bin/env bash
set -euo pipefail

for cmd in git python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required to record the Hermes server-audio receipt." >&2
    exit 1
  fi
done

require_env() {
  local name="$1"
  local value="${!name:-}"
  if [ -z "$value" ]; then
    echo "$name is required to record the Hermes server-audio receipt." >&2
    exit 2
  fi
}

require_true() {
  local name="$1"
  local value="${!name:-}"
  if [ "$value" != "true" ]; then
    echo "$name=true is required; do not record a server-audio receipt without that observation." >&2
    exit 2
  fi
}

require_false() {
  local name="$1"
  local value="${!name:-}"
  if [ "$value" != "false" ]; then
    echo "$name=false is required; local device STT/TTS fallback cannot be recorded as Hermes server audio." >&2
    exit 2
  fi
}

require_env WING_HERMES_SERVER_AUDIO_PROMPT
require_env WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY
# Required manual-observation gates: WING_HERMES_SERVER_AUDIO_TRANSPORT_OBSERVED=true,
# WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED=true,
# WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED=true,
# WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED=true,
# WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS=true,
# WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED=false, and
# WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY=false.
require_true WING_HERMES_SERVER_AUDIO_TRANSPORT_OBSERVED
require_true WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED
require_true WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED
require_true WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED
require_true WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS
require_false WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED
require_false WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY

receipt_path="${WING_HERMES_SERVER_AUDIO_RECEIPT:-build/receipts/hermes-server-audio-smoke.json}"
mkdir -p "$(dirname "$receipt_path")"
python3 - "$receipt_path" <<'PY'
import datetime, json, os, re, subprocess, sys

SECRET_PATTERN = re.compile(
    r'(bearer\s+\S+|basic\s+\S+|(?:authorization|cookie|set-cookie|x-api-key|x-auth-token)\s*[:=]\s*\S+|[a-z][a-z0-9+.-]*://[^/\s@]+@|(?:api[-_ ]?key|auth[-_ ]?token|token|secret|password|passwd|pwd|credential|credentials|auth)\s*(?:=|:)\s*\S+|secret[-_a-z0-9.]{4,}|sk-[a-z0-9_-]{12,}|gh[pousr]_[a-z0-9_]{20,}|xox[abprs]-[a-z0-9-]{20,}|eyJ[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.[a-z0-9_-]{8,})',
    re.IGNORECASE,
)
path = sys.argv[1]
prompt = os.environ['WING_HERMES_SERVER_AUDIO_PROMPT'].strip()
reply = os.environ['WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY'].strip()
for label, value in {
    'WING_HERMES_SERVER_AUDIO_PROMPT': prompt,
    'WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY': reply,
}.items():
    if not value:
        raise SystemExit(f'{label} is required; record a short non-sensitive observed excerpt instead.')
    if len(value) > 240:
        raise SystemExit(f'{label} is too long; record a short non-sensitive excerpt instead.')
    if SECRET_PATTERN.search(value):
        raise SystemExit(f'{label} appears to contain a secret; record a non-sensitive excerpt instead.')
if prompt.casefold() == reply.casefold():
    raise SystemExit('WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY must differ from the prompt excerpt.')
try:
    head_sha = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], text=True, stderr=subprocess.DEVNULL
    ).strip()
except Exception:
    head_sha = ''
receipt = {
    'kind': 'hermes_server_audio_smoke',
    'status': 'passed',
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'head_sha': head_sha,
    'server_audio_transport': 'hermes_realtime_or_audio_api',
    'input_audio_path': 'client_audio_to_hermes_server_audio',
    'response_audio_path': 'hermes_server_audio_to_client_playback',
    'prompt_excerpt': prompt,
    'provider_reply_excerpt': reply,
    'provider_reply_observed': os.environ['WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED'] == 'true',
    'server_audio_playback_observed': os.environ['WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED'] == 'true',
    'round_trip_observed': os.environ['WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED'] == 'true',
    'no_secret_leaks_observed': os.environ['WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS'] == 'true',
    'device_stt_used': os.environ['WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED'] == 'true',
    'local_tts_only': os.environ['WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY'] == 'true',
    'evidence_for': [
        'Hermes realtime/server audio input',
        'server-side audio turn',
        'provider-backed reply',
        'server audio playback',
    ],
    'not_evidence_for': [
        'physical Android microphone audio',
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
Hermes server-audio receipt written: $receipt_path

This receipt is Hermes realtime/server-audio evidence only when the manual
observations are truthful and the implementation actually used a Hermes
realtime/audio API. It is not Android physical-mic, native-host,
platform-workflow, deferred-surface, or whole-goal completion evidence by
itself; it is not whole-goal completion evidence.

Run WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any
completion claim.
EOF
