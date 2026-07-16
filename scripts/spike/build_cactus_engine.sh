#!/usr/bin/env bash
# Builds libcactus_engine.so (Android arm64-v8a) from the pinned Cactus commit
# and installs it into android/app/src/main/jniLibs/arm64-v8a/.
set -euo pipefail

CACTUS_SHA="49e12567c9d355a269c761619bc09eef796ab9b1"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wing/cactus"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
jni_dir="$repo_root/android/app/src/main/jniLibs/arm64-v8a"

if [[ ! -d "$CACHE_DIR/.git" ]]; then
  git clone https://github.com/cactus-compute/cactus.git "$CACHE_DIR"
fi
git -C "$CACHE_DIR" fetch --all --quiet
git -C "$CACHE_DIR" checkout --quiet "$CACTUS_SHA"

# Upstream's Android link uses -Wl,--exclude-libs,ALL, which drops the
# statically-linked engine's C API (cactus_init etc.) from the .so's dynamic
# symbol table — the Dart FFI binding then fails with "undefined symbol:
# cactus_init" at runtime. The API is compiled with explicit default
# visibility (CACTUS_FFI_EXPORT), so removing that one linker flag exports
# exactly the intended C surface while -fvisibility=hidden keeps the rest
# internal. Applied as a local patch; drop when upstream fixes the FFI build.
sed -i 's/target_link_options(cactus_flags INTERFACE -Wl,--exclude-libs,ALL)//' \
  "$CACHE_DIR/cactus-kernels/CMakeLists.txt"

# Force a clean relink so the patched flags actually apply.
rm -rf "$CACHE_DIR/android/build"

bash "$CACHE_DIR/android/build.sh"

# Restore the upstream tree so the patch never leaks into other checkouts.
git -C "$CACHE_DIR" checkout --quiet -- cactus-kernels/CMakeLists.txt

mkdir -p "$jni_dir"
so_path="$(find "$CACHE_DIR/android" -name libcactus_engine.so | head -1)"
if [[ -z "$so_path" ]]; then
  echo "libcactus_engine.so not produced; check NDK/CMake output above" >&2
  exit 1
fi
# grep -c (not -q) so grep consumes all input: -q exits early, readelf gets
# SIGPIPE, and pipefail would report failure even when the symbol exists.
if [[ "$(readelf --dyn-syms -W "$so_path" | grep -c ' cactus_init$')" -eq 0 ]]; then
  echo "Built .so does not export cactus_init; FFI would fail at runtime" >&2
  exit 1
fi
cp "$so_path" "$jni_dir/libcactus_engine.so"
echo "Installed $(stat -c %s "$jni_dir/libcactus_engine.so") bytes -> $jni_dir/libcactus_engine.so"
