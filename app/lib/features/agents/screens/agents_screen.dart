import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  NavivoxChannel? _subscribed;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }

    final agents = channel.state.agents;
    final selectedId = channel.state.selectedAgentId;

    return Scaffold(
      appBar: AppBar(title: const Text('Agents')),
      body: agents.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No agents loaded'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: channel.requestAgentList,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                for (final agent in agents)
                  ListTile(
                    leading: const Icon(Icons.smart_toy),
                    title: Text(agent.name),
                    subtitle: Text(agent.status),
                    trailing: agent.id == selectedId
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => channel.selectAgent(agent.id),
                  ),
              ],
            ),
    );
  }
}
