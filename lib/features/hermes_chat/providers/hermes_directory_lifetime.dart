import 'package:flutter/foundation.dart';

import '../gateways/hermes_gateway_directory.dart';

/// Passive reference to the directory owned by its production provider.
/// Does not construct, start, retain domain state for, or dispose the directory.
class HermesDirectoryLifetime extends ChangeNotifier {
  HermesGatewayDirectory? _current;

  HermesGatewayDirectory? get current => _current;

  void attach(HermesGatewayDirectory directory) {
    _current = directory;
    notifyListeners();
  }

  void detach(HermesGatewayDirectory directory) {
    if (!identical(_current, directory)) return;
    _current = null;
    notifyListeners();
  }
}
