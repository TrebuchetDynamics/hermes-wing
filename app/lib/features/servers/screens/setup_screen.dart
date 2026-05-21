import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _baseUrlController = TextEditingController(
    text: 'http://127.0.0.1:8765',
  );
  final _tokenController = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navivox')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connect to Gormes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Paste the base URL and token from '
                    '`gormes navivox connect-info` to open chat immediately.',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Gateway base URL',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Pairing token',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _connecting ? null : _connectGateway,
                    icon: _connecting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.hub),
                    label: const Text('Connect and talk'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    const Text(
                      'Run `gormes navivox connect-info` on the host and retry.',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connectGateway() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await ref
          .read(gatewayNavivoxChannelProvider)
          .connect(
            baseUrl: _baseUrlController.text.trim(),
            token: _tokenController.text.trim(),
          );
      if (mounted) context.go(AppRoutes.chats);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect to Gormes gateway.');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }
}
