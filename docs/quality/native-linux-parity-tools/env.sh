export PATH="$TMPDIR/parity-native/bin:$AUTOWORK_CACHE/flutter-3.44.2/bin:$AUTOWORK_CACHE/node-22.22.2/bin:$PATH"
export PUB_CACHE="$AUTOWORK_CACHE/dart-pub-3.12.2"
export PKG_CONFIG_PATH="$AUTOWORK_CACHE/linux-dev-noble-20261007/root/usr/lib/x86_64-linux-gnu/pkgconfig"
export LIBRARY_PATH="$AUTOWORK_CACHE/linux-dev-noble-20261007/root/usr/lib/x86_64-linux-gnu"
export CMAKE_BUILD_PARALLEL_LEVEL=2
export LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2
export GSETTINGS_BACKEND=memory GIO_USE_VFS=local GTK_USE_PORTAL=0
export HOME="$TMPDIR/parity-native/state/home"
export XDG_CONFIG_HOME="$TMPDIR/parity-native/state/config"
export XDG_DATA_HOME="$TMPDIR/parity-native/state/data"
export XDG_CACHE_HOME="$TMPDIR/parity-native/state/cache"
export XDG_STATE_HOME="$TMPDIR/parity-native/state/local-state"
export XDG_RUNTIME_DIR="$TMPDIR/parity-native/state/runtime"
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
export LD_PRELOAD="$TMPDIR/parity-native/bounded_bind.so"
unset DBUS_SESSION_BUS_ADDRESS DISPLAY
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$TMPDIR/parity-native/bin"
