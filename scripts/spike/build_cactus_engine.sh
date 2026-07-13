#!/usr/bin/env bash
# Builds libcactus_engine.so (Android arm64-v8a) from the pinned Cactus commit
# and installs it into android/app/src/main/jniLibs/arm64-v8a/.
set -euo pipefail

CACTUS_SHA="49e12567c9d355a269c761619bc09eef796ab9b1"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/navivox/cactus"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
jni_dir="$repo_root/android/app/src/main/jniLibs/arm64-v8a"

if [[ ! -d "$CACHE_DIR/.git" ]]; then
  git clone https://github.com/cactus-compute/cactus.git "$CACHE_DIR"
fi
git -C "$CACHE_DIR" fetch --all --quiet
git -C "$CACHE_DIR" checkout --quiet "$CACTUS_SHA"

bash "$CACHE_DIR/android/build.sh"

mkdir -p "$jni_dir"
so_path="$(find "$CACHE_DIR/android" -name libcactus_engine.so | head -1)"
if [[ -z "$so_path" ]]; then
  echo "libcactus_engine.so not produced; check NDK/CMake output above" >&2
  exit 1
fi
cp "$so_path" "$jni_dir/libcactus_engine.so"
echo "Installed $(stat -c %s "$jni_dir/libcactus_engine.so") bytes -> $jni_dir/libcactus_engine.so"
