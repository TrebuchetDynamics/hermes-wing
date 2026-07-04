#!/usr/bin/env bash
set -euo pipefail

workflow_name="${NAVIVOX_HERMES_PLATFORM_WORKFLOW:-Hermes platform smoke}"
ref="${NAVIVOX_WORKFLOW_REF:-$(git branch --show-current 2>/dev/null || true)}"
run_provider="${NAVIVOX_RUN_PROVIDER_SMOKE:-false}"
provider_url="${NAVIVOX_PROVIDER_HERMES_URL:-}"
run_android="${NAVIVOX_RUN_ANDROID_EMULATOR_SMOKE:-false}"
watch="${NAVIVOX_WATCH_WORKFLOW:-true}"
receipt_path="${NAVIVOX_PLATFORM_WORKFLOW_RECEIPT:-build/receipts/hermes-platform-workflow.json}"
existing_run_id="${NAVIVOX_PLATFORM_WORKFLOW_RUN_ID:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required to dispatch the Hermes platform workflow." >&2
  exit 1
fi

if [ -z "$ref" ]; then
  echo "Could not determine git ref. Set NAVIVOX_WORKFLOW_REF." >&2
  exit 1
fi

workflow_list="$(gh workflow list 2>&1 || true)"
gh_auth_status="$(gh auth status 2>&1 || true)"
if ! printf '%s\n' "$workflow_list" | grep -Fq "$workflow_name"; then
  cat >&2 <<EOF
Workflow '$workflow_name' is not visible to gh.
Publish .github/workflows/hermes-platform-smoke.yml to the remote branch first,
or ensure the current token/repository can read workflows.
EOF
  if printf '%s\n' "$gh_auth_status" | grep -Fq "Token scopes:" && ! printf '%s\n' "$gh_auth_status" | grep -Fq "'workflow'"; then
    cat >&2 <<'EOF'

Active gh token scopes do not include 'workflow'. Refresh GitHub credentials
with workflow scope before pushing/publishing .github/workflows/hermes-platform-smoke.yml.
EOF
  fi
  cat >&2 <<EOF

Visible workflows:
$workflow_list
EOF
  exit 2
fi

if [ "$run_provider" = "true" ] && [ -z "$provider_url" ]; then
  echo "NAVIVOX_PROVIDER_HERMES_URL is required when NAVIVOX_RUN_PROVIDER_SMOKE=true." >&2
  exit 1
fi

if [ -n "$existing_run_id" ]; then
  run_id="$existing_run_id"
  printf 'Using existing %s run %s\n' "$workflow_name" "$run_id"
else
  args=(
    workflow run "$workflow_name"
    --ref "$ref"
    -f "run_provider_smoke=$run_provider"
    -f "provider_url=$provider_url"
    -f "run_android_emulator_smoke=$run_android"
  )

  printf 'Dispatching %s on %s\n' "$workflow_name" "$ref"
  gh "${args[@]}"

  # Give GitHub a moment to create the run, then show the newest matching run.
  sleep "${NAVIVOX_WORKFLOW_RUN_DISCOVERY_DELAY_SECONDS:-5}"
  run_id="$(gh run list --workflow "$workflow_name" --branch "$ref" --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
  if [ -z "$run_id" ]; then
    cat >&2 <<'EOF'
Workflow dispatched, but no run id was visible yet. This is not a platform receipt.
Check gh run list/gh run view and collect successful job evidence before claiming readiness.
EOF
    exit 4
  fi
fi

echo "Run: $(gh run view "$run_id" --json url --jq '.url')"

if [ "$watch" = "true" ]; then
  gh run watch "$run_id" --exit-status
  mkdir -p "$(dirname "$receipt_path")"
  run_json="$(mktemp -t navivox-platform-run.XXXXXX.json)"
  artifacts_json="$(mktemp -t navivox-platform-artifacts.XXXXXX.json)"
  jobs_json="$(mktemp -t navivox-platform-jobs.XXXXXX.json)"
  gh run view "$run_id" \
    --json databaseId,url,workflowName,headBranch,headSha,status,conclusion,createdAt,updatedAt \
    >"$run_json"
  gh run view "$run_id" --json jobs --jq '.jobs' >"$jobs_json"
  gh api "repos/{owner}/{repo}/actions/runs/$run_id/artifacts" \
    --jq '[.artifacts[] | {id, name, size_in_bytes, expired, archive_download_url}]' >"$artifacts_json"
  python3 - "$run_json" "$artifacts_json" "$jobs_json" "$receipt_path" <<'PY'
import datetime, json, sys
run = json.load(open(sys.argv[1], encoding='utf-8'))
artifact_details = json.load(open(sys.argv[2], encoding='utf-8'))
job_details = json.load(open(sys.argv[3], encoding='utf-8'))
artifacts = [
    artifact.get('name') if isinstance(artifact, dict) else artifact
    for artifact in artifact_details
]
required_native_artifacts = [
    'navivox-windows-debug-bundle',
    'navivox-ios-simulator-app',
    'navivox-macos-debug-app',
]
artifact_by_name = {
    artifact.get('name'): artifact
    for artifact in artifact_details
    if isinstance(artifact, dict)
}
missing_required_artifacts = [
    name for name in required_native_artifacts if name not in set(artifacts)
]
required_native_jobs = [
    'Windows desktop build',
    'iOS simulator build',
    'macOS desktop build',
]
invalid_required_artifacts = []
for name in required_native_artifacts:
    artifact = artifact_by_name.get(name)
    if not artifact:
        continue
    if not artifact.get('id'):
        invalid_required_artifacts.append(f'{name}:missing-id')
    if int(artifact.get('size_in_bytes') or 0) <= 0:
        invalid_required_artifacts.append(f'{name}:empty-artifact')
    if artifact.get('expired') is not False:
        invalid_required_artifacts.append(f'{name}:expired')
    if not artifact.get('archive_download_url'):
        invalid_required_artifacts.append(f'{name}:missing-download-url')
job_by_name = {
    job.get('name'): job
    for job in job_details
    if isinstance(job, dict)
}
missing_required_jobs = [
    name for name in required_native_jobs if name not in job_by_name
]
invalid_required_jobs = []
for name in required_native_jobs:
    job = job_by_name.get(name)
    if not job:
        continue
    if job.get('status') != 'completed':
        invalid_required_jobs.append(f'{name}:status={job.get("status")}')
    if job.get('conclusion') != 'success':
        invalid_required_jobs.append(f'{name}:conclusion={job.get("conclusion")}')
passed = (
    run.get('status') == 'completed'
    and run.get('conclusion') == 'success'
    and not missing_required_artifacts
    and not invalid_required_artifacts
    and not missing_required_jobs
    and not invalid_required_jobs
)
receipt = {
    'kind': 'hermes_platform_workflow',
    'status': 'passed' if passed else 'failed',
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'workflow': run.get('workflowName'),
    'run_id': run.get('databaseId'),
    'url': run.get('url'),
    'head_branch': run.get('headBranch'),
    'head_sha': run.get('headSha'),
    'run_status': run.get('status'),
    'conclusion': run.get('conclusion'),
    'created_at': run.get('createdAt'),
    'updated_at': run.get('updatedAt'),
    'artifacts': artifacts,
    'artifact_details': artifact_details,
    'required_native_artifacts': required_native_artifacts,
    'missing_required_artifacts': missing_required_artifacts,
    'invalid_required_artifacts': invalid_required_artifacts,
    'job_details': job_details,
    'required_native_jobs': required_native_jobs,
    'missing_required_jobs': missing_required_jobs,
    'invalid_required_jobs': invalid_required_jobs,
    'evidence_for': [
        'published Hermes platform workflow',
        'Windows desktop native-host build artifact',
        'iOS simulator native-host build artifact',
        'macOS desktop native-host build artifact',
    ],
    'not_evidence_for': [
        'physical Android microphone audio',
        'Hermes realtime/server audio',
        'deferred Hermes Desktop parity surfaces',
        'whole-goal completion',
    ],
}
receipt_path = sys.argv[4]
json.dump(receipt, open(receipt_path, 'w', encoding='utf-8'), indent=2)
open(receipt_path, 'a', encoding='utf-8').write('\n')
if not passed:
    if missing_required_artifacts:
        print(
            'Missing required native artifacts: ' + ', '.join(missing_required_artifacts),
            file=sys.stderr,
        )
    if invalid_required_artifacts:
        print(
            'Invalid required native artifacts: ' + ', '.join(invalid_required_artifacts),
            file=sys.stderr,
        )
    if missing_required_jobs:
        print(
            'Missing required native jobs: ' + ', '.join(missing_required_jobs),
            file=sys.stderr,
        )
    if invalid_required_jobs:
        print(
            'Invalid required native jobs: ' + ', '.join(invalid_required_jobs),
            file=sys.stderr,
        )
    sys.exit(5)
PY
  rm -f "$run_json" "$artifacts_json" "$jobs_json"
  echo "Platform workflow receipt written: $receipt_path"
else
  cat <<'EOF'
Workflow dispatch succeeded, but NAVIVOX_WATCH_WORKFLOW=false did not wait for job results.
Collect successful Windows/iOS/macOS/Android/Linux job receipts before claiming platform readiness.
EOF
fi
