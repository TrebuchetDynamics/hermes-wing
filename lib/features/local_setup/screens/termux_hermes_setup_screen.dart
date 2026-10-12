import 'package:flutter/material.dart';

import '../../hermes_chat/screens/hermes_add_screen.dart';
import '../../hermes_chat/screens/hermes_chat_screen.dart';

/// Reuse direct Agent preparation and authentication; no bootstrap or pairing.
class TermuxHermesSetupScreen extends StatelessWidget {
  const TermuxHermesSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => const HermesAddScreen(
    mode: HermesConnectionMode.local,
    fromWelcome: true,
  );
}
