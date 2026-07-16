import 'package:flutter/material.dart';

import 'app.dart';
import 'features/needle_spike/needle_spike_flag.dart';

void main() {
  if (needleSpikeEnabled) {
    // Release builds keep the semantics tree off until an assistive service
    // asks for it, which blinds UI-automation tools (Maestro) used for the
    // Needle spike evaluation. Compile-time gated: tree-shaken out of
    // default builds along with the rest of the spike.
    WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  }
  runApp(const WingApp());
}
