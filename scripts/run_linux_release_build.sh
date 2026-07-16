#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required for the Linux release build." >&2
  exit 1
fi

if pkg-config --exists 'libsecret-1 >= 0.18.4' 2>/dev/null; then
  flutter build linux --release
  exit 0
fi

for cmd in apt-get dpkg pkg-config python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for rootless Linux dependency setup." >&2
    exit 1
  fi
done

work="${WING_LINUX_BUILD_DEPS_DIR:-$(mktemp -d -t wing-linux-deps.XXXXXX)}"
mkdir -p "$work"
work="$(python3 - "$work" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
prefix="$work/prefix"
pcdir="$work/pkgconfig"
debdir="$work/debs"
mkdir -p "$prefix" "$pcdir" "$debdir"

(
  cd "$debdir"
  apt-get download libsecret-1-dev libgcrypt20-dev libgpg-error-dev
)

for deb in "$debdir"/*.deb; do
  dpkg -x "$deb" "$prefix"
done

if [ -d "$prefix/usr/lib/x86_64-linux-gnu/pkgconfig" ]; then
  cp "$prefix"/usr/lib/x86_64-linux-gnu/pkgconfig/*.pc "$pcdir"/
fi
if [ -d "$prefix/usr/share/pkgconfig" ]; then
  cp "$prefix"/usr/share/pkgconfig/*.pc "$pcdir"/ 2>/dev/null || true
fi

for pc in "$pcdir"/*.pc; do
  [ -e "$pc" ] || continue
  python3 - "$pc" "$prefix" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
prefix = Path(sys.argv[2]) / 'usr'
text = path.read_text()
text = text.replace('prefix=/usr', f'prefix={prefix}')
path.write_text(text)
PY
done

# The extracted libsecret dev symlink points at a runtime library supplied by
# the system package in this container. Repoint it so CMake find_library works.
if [ -e /usr/lib/x86_64-linux-gnu/libsecret-1.so.0 ]; then
  ln -sf /usr/lib/x86_64-linux-gnu/libsecret-1.so.0 \
    "$prefix/usr/lib/x86_64-linux-gnu/libsecret-1.so"
fi

rm -rf build/linux
PKG_CONFIG_PATH="$pcdir${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
CPATH="$prefix/usr/include${CPATH:+:$CPATH}" \
  flutter build linux --release
