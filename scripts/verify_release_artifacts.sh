#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 DIST_DIR vVERSION-alpha.N" >&2
  exit 2
fi

dist=$(realpath "$1")
tag=$2
version=${tag#v}
expected_cert=${WING_RELEASE_CERT_SHA256:-}
source_revision=${GITHUB_SHA:-}
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temp_dir=$(mktemp -d)
server_pid=
cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$temp_dir"
}
trap cleanup EXIT

[[ -d "$dist" ]] || { echo "missing artifact directory: $dist" >&2; exit 1; }
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+$ ]] || {
  echo "invalid alpha tag: $tag" >&2
  exit 1
}
[[ -n "$expected_cert" ]] || {
  echo "WING_RELEASE_CERT_SHA256 is required" >&2
  exit 1
}
[[ "$source_revision" =~ ^[0-9a-f]{40}$ ]] || {
  echo "GITHUB_SHA must identify the immutable source revision" >&2
  exit 1
}

expected=(
  android-release-evidence.json
  android-termux-bootstrap.json
  linux-release-evidence.json
  web-release-evidence.json
  wing-link-release-evidence.json
  hermes-wing-android.aab
  hermes-wing-android.aab.sha256
  hermes-wing-android.apk
  hermes-wing-android.apk.sha256
  hermes-wing-linux-x64.tar.gz
  hermes-wing-linux-x64.tar.gz.sha256
  hermes-wing-web.tar.gz
  hermes-wing-web.tar.gz.sha256
  wing-link-android-arm64
  wing-link-checksums.sha256
  wing-link-darwin-amd64
  wing-link-darwin-arm64
  wing-link-linux-amd64
  wing-link-linux-arm64
  wing-link-windows-amd64.exe
)
mapfile -t expected_sorted < <(printf '%s\n' "${expected[@]}" | sort)
mapfile -t actual < <(find "$dist" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | sort)
if [[ "$(printf '%s\n' "${actual[@]}")" != "$(printf '%s\n' "${expected_sorted[@]}")" ]]; then
  echo "release artifact set does not match the allowlist" >&2
  diff -u <(printf '%s\n' "${expected_sorted[@]}") <(printf '%s\n' "${actual[@]}") || true
  exit 1
fi
if find "$dist" -mindepth 1 -maxdepth 1 ! -type f -print -quit | grep -q .; then
  echo "release artifact directory contains a non-file entry" >&2
  exit 1
fi
for name in "${expected[@]}"; do
  [[ -s "$dist/$name" ]] || { echo "empty release artifact: $name" >&2; exit 1; }
done

# Evidence is checked before any archive extraction or artifact execution.
for target in android linux web wing-link; do
  TAG="$tag" node "$repo_root/scripts/release_evidence.mjs" verify "$target" "$dist"
done

verify_checksum_manifest() {
  local manifest=$1
  shift
  python3 - "$manifest" "$@" <<'PY'
import re
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
expected = sorted(sys.argv[2:])
actual = []
for line in manifest.read_text().splitlines():
    match = re.fullmatch(r"([0-9a-fA-F]{64}) [ *]([^/\\]+)", line)
    if match is None:
        raise SystemExit(
            f"checksum manifest does not exactly cover expected artifacts: {manifest.name}"
        )
    actual.append(match.group(2))
if sorted(actual) != expected or len(actual) != len(set(actual)):
    raise SystemExit(
        f"checksum manifest does not exactly cover expected artifacts: {manifest.name}"
    )
PY
}

verify_checksum_manifest "$dist/hermes-wing-android.apk.sha256" \
  hermes-wing-android.apk
verify_checksum_manifest "$dist/hermes-wing-android.aab.sha256" \
  hermes-wing-android.aab
verify_checksum_manifest "$dist/hermes-wing-linux-x64.tar.gz.sha256" \
  hermes-wing-linux-x64.tar.gz
verify_checksum_manifest "$dist/hermes-wing-web.tar.gz.sha256" \
  hermes-wing-web.tar.gz
verify_checksum_manifest "$dist/wing-link-checksums.sha256" \
  wing-link-android-arm64 \
  wing-link-darwin-amd64 \
  wing-link-darwin-arm64 \
  wing-link-linux-amd64 \
  wing-link-linux-arm64 \
  wing-link-windows-amd64.exe

for command in curl file jarsigner keytool python3 qemu-aarch64-static sha256sum tar timeout unzip xvfb-run; do
  command -v "$command" >/dev/null || { echo "missing command: $command" >&2; exit 1; }
done

apksigner=${APKSIGNER:-}
if [[ -z "$apksigner" && -n "${ANDROID_HOME:-}" ]]; then
  apksigner=$(find "$ANDROID_HOME/build-tools" -name apksigner -type f -print 2>/dev/null | sort -V | tail -1)
fi
[[ -x "$apksigner" ]] || { echo "APKSIGNER must name an executable apksigner" >&2; exit 1; }

(
  cd "$dist"
  sha256sum -c hermes-wing-android.apk.sha256
  sha256sum -c hermes-wing-android.aab.sha256
  sha256sum -c hermes-wing-linux-x64.tar.gz.sha256
  sha256sum -c hermes-wing-web.tar.gz.sha256
  sha256sum -c wing-link-checksums.sha256
)

unzip -tq "$dist/hermes-wing-android.apk" >/dev/null
unzip -tq "$dist/hermes-wing-android.aab" >/dev/null
python3 - "$dist" "$repo_root" "$tag" "$source_revision" <<'PY'
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path


dist = Path(sys.argv[1])
repo = Path(sys.argv[2])
tag = sys.argv[3]
source_revision = sys.argv[4]
asset_path = "assets/flutter_assets/assets/config/termux_bootstrap.json"
aab_suffix = "/assets/flutter_assets/assets/config/termux_bootstrap.json"


def read_unique(archive: Path, predicate) -> bytes:
    with zipfile.ZipFile(archive) as bundle:
        matches = [name for name in bundle.namelist() if predicate(name)]
        if len(matches) != 1:
            raise SystemExit(
                f"{archive.name} must contain exactly one Termux bootstrap metadata asset"
            )
        return bundle.read(matches[0])


apk_metadata = read_unique(
    dist / "hermes-wing-android.apk", lambda name: name == asset_path
)
aab_metadata = read_unique(
    dist / "hermes-wing-android.aab",
    lambda name: name == asset_path or name.endswith(aab_suffix),
)
if apk_metadata != aab_metadata:
    raise SystemExit("APK and AAB Termux bootstrap metadata differ")
def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate metadata key: {key}")
        result[key] = value
    return result


try:
    metadata = json.loads(apk_metadata, object_pairs_hook=unique_object)
except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as error:
    raise SystemExit("invalid packaged Termux bootstrap metadata") from error
expected_keys = {
    "available",
    "tag",
    "installer_commit",
    "installer_sha256",
    "asset_sha256",
    "asset_size",
}
if set(metadata) != expected_keys or metadata.get("available") is not True:
    raise SystemExit("packaged Termux bootstrap metadata is unavailable or malformed")
if metadata.get("tag") != tag or metadata.get("installer_commit") != source_revision:
    raise SystemExit("packaged Termux bootstrap tag or source revision mismatch")
for key in ("installer_sha256", "asset_sha256"):
    if not isinstance(metadata.get(key), str) or not re.fullmatch(
        r"[0-9a-f]{64}", metadata[key]
    ):
        raise SystemExit(f"invalid packaged {key}")
asset_size = metadata.get("asset_size")
if not isinstance(asset_size, int) or isinstance(asset_size, bool) or not 1 <= asset_size <= 50 * 1024 * 1024:
    raise SystemExit("invalid packaged Wing Link asset size")
wing_link = dist / "wing-link-android-arm64"
actual_asset = wing_link.read_bytes()
if len(actual_asset) != asset_size or hashlib.sha256(actual_asset).hexdigest() != metadata["asset_sha256"]:
    raise SystemExit("packaged Wing Link metadata does not match the released asset")
installer = repo / "install-wing-link.sh"
installer_bytes = installer.read_bytes()
if not 1 <= len(installer_bytes) <= 1024 * 1024:
    raise SystemExit("installer source exceeds the 1 MiB command limit")
if hashlib.sha256(installer_bytes).hexdigest() != metadata["installer_sha256"]:
    raise SystemExit("packaged installer digest does not match the source revision")
manifest_matches = []
for line in (dist / "wing-link-checksums.sha256").read_text().splitlines():
    match = re.fullmatch(r"([0-9a-fA-F]{64}) [ *]([^/\\]+)", line)
    if match and match.group(2) == wing_link.name:
        manifest_matches.append(match.group(1).lower())
if manifest_matches != [metadata["asset_sha256"]]:
    raise SystemExit("packaged Wing Link digest does not match the release manifest")
PY
apk_report=$($apksigner verify --verbose --print-certs "$dist/hermes-wing-android.apk")
mapfile -t apk_certs < <(printf '%s\n' "$apk_report" | awk -F': ' '/Signer #[0-9]+ certificate SHA-256 digest:/{print $2}')
mapfile -t aab_certs < <(keytool -printcert -jarfile "$dist/hermes-wing-android.aab" | awk -F': ' '/SHA256:/{print $2}')
normalize_digest() { printf '%s' "$1" | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]'; }
expected_cert=$(normalize_digest "$expected_cert")
[[ ${#apk_certs[@]} -eq 1 ]] || {
  echo "APK must have exactly one signing certificate" >&2
  exit 1
}
[[ ${#aab_certs[@]} -eq 1 ]] || {
  echo "AAB must have exactly one signing certificate" >&2
  exit 1
}
[[ "$(normalize_digest "${apk_certs[0]}")" == "$expected_cert" ]] || {
  echo "APK signing certificate does not match WING_RELEASE_CERT_SHA256" >&2
  exit 1
}
[[ "$(normalize_digest "${aab_certs[0]}")" == "$expected_cert" ]] || {
  echo "AAB signing certificate does not match WING_RELEASE_CERT_SHA256" >&2
  exit 1
}
aab_signature_report=$(LC_ALL=C jarsigner -verify -verbose \
  "$dist/hermes-wing-android.aab" 2>&1)
printf '%s\n' "$aab_signature_report" | grep -q 'jar verified.'
if printf '%s\n' "$aab_signature_report" | grep -Eq '^[[:space:]]*\?'; then
  echo "AAB contains unsigned payload entries" >&2
  exit 1
fi

python3 - "$dist" "$temp_dir" <<'PY'
import posixpath
import sys
import tarfile
from pathlib import Path, PurePosixPath

dist = Path(sys.argv[1])
out = Path(sys.argv[2])

MAX_MEMBERS = 50_000
MAX_EXPANDED_BYTES = 4 * 1024 * 1024 * 1024


def safe_extract(archive: Path, destination: Path) -> None:
    with tarfile.open(archive, "r:gz") as bundle:
        members = bundle.getmembers()
        if len(members) > MAX_MEMBERS:
            raise SystemExit(f"archive has too many entries: {archive.name}")
        if sum(member.size for member in members) > MAX_EXPANDED_BYTES:
            raise SystemExit(f"archive expands beyond the size limit: {archive.name}")
        seen_paths = set()
        for member in members:
            path = PurePosixPath(member.name)
            canonical_path = str(path)
            if canonical_path in seen_paths:
                raise SystemExit(f"duplicate archive path in {archive.name}: {member.name}")
            seen_paths.add(canonical_path)
            if member.islnk():
                raise SystemExit(f"hard links are not allowed in {archive.name}: {member.name}")
            if not (member.isreg() or member.isdir() or member.issym()):
                raise SystemExit(f"unsafe archive entry type in {archive.name}: {member.name}")
            if path.is_absolute() or ".." in path.parts:
                raise SystemExit(f"unsafe archive path in {archive.name}: {member.name}")
            if member.issym():
                target = posixpath.normpath(posixpath.join(posixpath.dirname(member.name), member.linkname))
                target_path = PurePosixPath(target)
                if target_path.is_absolute() or ".." in target_path.parts:
                    raise SystemExit(f"unsafe archive link in {archive.name}: {member.name}")
        bundle.extractall(destination)

linux = out / "linux"
web = out / "web"
linux.mkdir()
web.mkdir()
safe_extract(dist / "hermes-wing-linux-x64.tar.gz", linux)
safe_extract(dist / "hermes-wing-web.tar.gz", web)
for required in (linux / "bundle/wing", linux / "bundle/wing-link", web / "index.html", web / "main.dart.js", web / "flutter_bootstrap.js"):
    if not required.is_file() or required.is_symlink():
        raise SystemExit(f"release archive is missing a regular file at {required.relative_to(out)}")
PY

file "$dist/wing-link-linux-amd64" | grep -Eq 'ELF 64-bit.*x86-64'
file "$dist/wing-link-linux-arm64" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)'
file "$dist/wing-link-darwin-amd64" | grep -Eq 'Mach-O 64-bit.*x86_64'
file "$dist/wing-link-darwin-arm64" | grep -Eq 'Mach-O 64-bit.*arm64'
file "$dist/wing-link-windows-amd64.exe" | grep -Eq 'PE32\+.*x86-64'
file "$dist/wing-link-android-arm64" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)'

chmod +x "$dist/wing-link-linux-amd64" "$dist/wing-link-linux-arm64" "$temp_dir/linux/bundle/wing"
[[ "$(timeout 10 "$dist/wing-link-linux-amd64" version)" == "$version" ]]
[[ "$(timeout 10 qemu-aarch64-static "$dist/wing-link-linux-arm64" version)" == "$version" ]]

linux_log="$temp_dir/linux-smoke.log"
xvfb-run -a bash -c '
  app=$1
  log=$2
  "$app" >"$log" 2>&1 &
  pid=$!
  sleep 5
  kill -0 "$pid"
  kill "$pid"
  wait "$pid" || true
' bash "$temp_dir/linux/bundle/wing" "$linux_log"

port=${WING_RELEASE_WEB_SMOKE_PORT:-8877}
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$temp_dir/web" >"$temp_dir/web-server.log" 2>&1 &
server_pid=$!
for _ in {1..30}; do
  if curl -fsS "http://127.0.0.1:$port/" >/dev/null; then break; fi
  sleep 1
done
curl -fsS "http://127.0.0.1:$port/main.dart.js" >/dev/null
(
  cd "$repo_root"
  RELEASE_ARTIFACT_BASE_URL="http://127.0.0.1:$port/" \
    npx playwright test --config=playwright.config.mjs \
      playwright/tests/regression/release-artifact.spec.mjs
)

python3 - "$dist" "$tag" "$expected_cert" <<'PY'
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

dist = Path(sys.argv[1])
tag = sys.argv[2]
certificate = sys.argv[3]
receipt_name = "release-verification-receipt.json"
artifacts = []
for path in sorted(dist.iterdir()):
    if path.is_file() and path.name != receipt_name:
        artifacts.append({
            "name": path.name,
            "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
receipt = {
    "schema_version": 1,
    "tag": tag,
    "source_revision": os.environ.get("GITHUB_SHA", "local"),
    "verified_at": datetime.now(timezone.utc).isoformat(),
    "android_certificate_sha256": certificate,
    "checks": [
        "exact_allowlist",
        "sha256_sidecars",
        "android_apk_signature",
        "android_aab_signature",
        "archive_path_safety",
        "linux_bundle_launch",
        "web_browser_launch",
        "wing_link_linux_amd64_version",
        "wing_link_linux_arm64_version",
        "foreign_binary_formats",
    ],
    "artifacts": artifacts,
}
(dist / receipt_name).write_text(json.dumps(receipt, indent=2) + "\n")
PY

echo "Verified exact release artifacts for $tag"
