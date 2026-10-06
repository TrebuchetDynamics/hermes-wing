import 'dart:io';

/// Accept only a launcher-created directory directly under the configured temp
/// root, with exact config identity. Never accept a prefix of a personal path.
String requireLinuxTestRoot(String prefix) {
  final root = Platform.environment['WING_LINUX_TEST_ROOT'];
  final config = Platform.environment['XDG_CONFIG_HOME'];
  if (root == null ||
      config != '$root/config' ||
      !Directory(root).existsSync() ||
      Directory(root).resolveSymbolicLinksSync() != root ||
      Directory(root).parent.resolveSymbolicLinksSync() !=
          Directory.systemTemp.resolveSymbolicLinksSync() ||
      !RegExp(
        '^${RegExp.escape(prefix)}[a-zA-Z0-9]+\$',
      ).hasMatch(root.split(Platform.pathSeparator).last) ||
      !File('$root/.wing-linux-test-owner').existsSync()) {
    throw StateError('Use the isolated Linux test launcher.');
  }
  return root;
}

/// A live grant must be the exact canonical child of the validated test root.
String requireLinuxLiveDirectoryRoot(String root, String testRoot) {
  if (root != '$testRoot/grant-root' ||
      !Directory(root).existsSync() ||
      Directory(root).resolveSymbolicLinksSync() != root ||
      Directory(root).parent.resolveSymbolicLinksSync() != testRoot) {
    throw StateError('An owned synthetic directory root is required.');
  }
  return root;
}
