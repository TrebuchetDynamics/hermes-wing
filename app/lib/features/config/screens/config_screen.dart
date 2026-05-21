import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  NavivoxChannel? _subscribed;
  String? _editingField;
  final TextEditingController _controller = TextEditingController();

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _controller.dispose();
    super.dispose();
  }

  void _save(String field, String type) {
    final raw = _controller.text;
    Object? value = raw;
    if (type == 'number') {
      value = num.tryParse(raw) ?? raw;
    } else if (type == 'boolean') {
      value = raw.toLowerCase() == 'true';
    }
    ref.read(navivoxChannelProvider).sendConfigSet(field: field, value: value);
    setState(() => _editingField = null);
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }

    final schema = channel.state.configSchema;
    final values = channel.state.configValues;
    final fields = (schema?['fields'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Config')),
      body: fields.isEmpty
          ? const Center(child: Text('No config available'))
          : ListView(
              children: [
                for (final raw in fields)
                  if (raw is Map)
                    _ConfigRow(
                      field: raw['name'] as String,
                      type: (raw['type'] as String?) ?? 'string',
                      required: raw['required'] == true,
                      value: values[raw['name']],
                      isEditing: _editingField == raw['name'],
                      controller: _controller,
                      onEdit: () {
                        _controller.text = '${values[raw['name']] ?? ''}';
                        setState(() => _editingField = raw['name'] as String);
                      },
                      onCancel: () => setState(() => _editingField = null),
                      onSave: () => _save(
                        raw['name'] as String,
                        (raw['type'] as String?) ?? 'string',
                      ),
                    ),
              ],
            ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.field,
    required this.type,
    required this.required,
    required this.value,
    required this.isEditing,
    required this.controller,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final String field;
  final String type;
  final bool required;
  final Object? value;
  final bool isEditing;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(
                    key: ValueKey('config-input-$field'),
                    controller: controller,
                    keyboardType: type == 'number'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                  )
                else
                  Text(value == null ? '—' : '$value'),
              ],
            ),
          ),
          if (isEditing) ...[
            IconButton(
              key: ValueKey('config-save-$field'),
              icon: const Icon(Icons.check),
              onPressed: onSave,
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
          ] else
            IconButton(
              key: ValueKey('config-edit-$field'),
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
