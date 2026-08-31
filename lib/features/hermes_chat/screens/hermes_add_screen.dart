import 'package:flutter/material.dart';

import 'hermes_chat_screen.dart';

/// The connection setup surface. Chat owns the connection controller so adding
/// a Hermes endpoint cannot drift from reconnect and secure persistence rules.
class HermesAddScreen extends StatelessWidget {
  const HermesAddScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const HermesChatScreen(initiallyEditingConnection: true);
}
