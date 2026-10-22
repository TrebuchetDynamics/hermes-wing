import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/hermes/setup/hermes_gateway_invite.dart';
import '../../../l10n/app_localizations.dart';

/// Only accepts the new non-secret metadata format. No intent/share handling.
class GatewayQrScanner extends StatefulWidget {
  const GatewayQrScanner({super.key});

  @override
  State<GatewayQrScanner> createState() => _GatewayQrScannerState();
}

class _GatewayQrScannerState extends State<GatewayQrScanner> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _settled = false;
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _capture(BarcodeCapture capture) {
    if (_settled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      try {
        final invite = HermesGatewayInvite.decode(raw);
        _settled = true;
        _controller.stop();
        Navigator.of(context).pop(invite);
        return;
      } catch (_) {
        if (!_invalid) setState(() => _invalid = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.gatewayScan)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.gatewayQrSafe),
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _capture,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.gatewayCameraFailed),
                ),
              ),
            ),
          ),
          if (_invalid)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.gatewayInvalidQr),
              ),
            ),
        ],
      ),
    );
  }
}
