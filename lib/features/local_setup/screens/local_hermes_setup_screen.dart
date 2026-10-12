import 'package:flutter/material.dart';

import '../../hermes_chat/screens/hermes_add_screen.dart';
import '../../hermes_chat/screens/hermes_chat_screen.dart';

/// Reuse direct Agent authentication and metadata-only Hermes-home discovery.
class LocalHermesSetupScreen extends StatelessWidget {
  const LocalHermesSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => const HermesAddScreen(
    mode: HermesConnectionMode.local,
    fromWelcome: true,
  );
}
