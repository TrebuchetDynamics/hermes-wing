import 'dart:io';

import 'local_hermes_home_types.dart';

LocalHermesHomePlatform createLocalHermesHomePlatform() =>
    IoLocalHermesHomePlatform(
      userHome: Platform.isLinux ? Platform.environment['HOME'] : null,
    );

class IoLocalHermesHomePlatform implements LocalHermesHomePlatform {
  IoLocalHermesHomePlatform({this.userHome});

  @override
  final String? userHome;
  @override
  bool get isSupported => Platform.isLinux;

  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) async {
    if (!isSupported) {
      return const LocalHermesHomeInspection.unavailable(
        LocalHermesHomeStatus.unsupported,
      );
    }
    try {
      final canonical = await Directory(path).resolveSymbolicLinks();
      final metadata = await Directory(canonical).stat();
      if (metadata.type == FileSystemEntityType.notFound) {
        // stat may mask permission failures. Do not claim absence or success.
        return const LocalHermesHomeInspection.unavailable(
          LocalHermesHomeStatus.unreadable,
        );
      }
      if (metadata.type != FileSystemEntityType.directory) {
        return const LocalHermesHomeInspection.unavailable(
          LocalHermesHomeStatus.notDirectory,
        );
      }
      return LocalHermesHomeInspection.directory(canonical);
    } on FileSystemException catch (error) {
      final status = switch (error.osError?.errorCode) {
        2 => LocalHermesHomeStatus.absent,
        20 => LocalHermesHomeStatus.notDirectory,
        _ => LocalHermesHomeStatus.unreadable,
      };
      return LocalHermesHomeInspection.unavailable(status);
    }
  }
}
