import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/hermes/setup/hermes_gateway_invite.dart';
import '../../../l10n/app_localizations.dart';

/// Operator supplies an already-reachable gateway, never discovers local keys.
class GatewayQrBuilder extends StatefulWidget {
  const GatewayQrBuilder({super.key});
  @override
  State<GatewayQrBuilder> createState() => _GatewayQrBuilderState();
}

class _GatewayQrBuilderState extends State<GatewayQrBuilder> {
  final _origin = TextEditingController();
  final _profile = TextEditingController(text: 'default');
  HermesGatewayInvite? _invite;
  bool _invalid = false;
  @override
  void dispose() {
    _origin.dispose();
    _profile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.gatewayQrCreate),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.gatewayQrSafe),
              TextField(
                controller: _origin,
                decoration: InputDecoration(labelText: s.gatewayAddress),
                autocorrect: false,
                onChanged: (_) => setState(() => _invite = null),
              ),
              TextField(
                controller: _profile,
                decoration: InputDecoration(labelText: s.gatewayProfile),
                autocorrect: false,
                onChanged: (_) => setState(() => _invite = null),
              ),
              FilledButton(
                onPressed: () {
                  try {
                    final value = HermesGatewayInvite(
                      origin: Uri.parse(_origin.text.trim()),
                      profile: _profile.text.trim(),
                    );
                    setState(() {
                      _invite = value;
                      _invalid = false;
                    });
                  } catch (_) {
                    setState(() {
                      _invite = null;
                      _invalid = true;
                    });
                  }
                },
                child: Text(s.gatewayQrCreate),
              ),
              if (_invalid) Text(s.gatewayInvalidQr),
              if (_invite != null)
                Semantics(
                  label: s.gatewayQrSafe,
                  child: Center(
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: QrImageView(
                        data: _invite!.encode(),
                        size: 260,
                        semanticsLabel: s.gatewayQrSafe,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.connectionInformationClose),
        ),
      ],
    );
  }
}
