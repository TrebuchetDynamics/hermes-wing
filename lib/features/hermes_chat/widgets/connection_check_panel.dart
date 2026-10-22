import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/hermes/client/hermes_api_client.dart';
import '../../../core/hermes/client/hermes_api_config.dart';
import '../../../core/hermes/policy/hermes_endpoint_security.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../core/hermes/shared/hermes_api_http.dart';
import '../../../l10n/app_localizations.dart';
import 'connection_setup_guide.dart';
import 'connection_access_help.dart';

/// Explicit read-only discovery, independent of Chat and secure persistence.
class ConnectionCheckPanel extends StatefulWidget {
  const ConnectionCheckPanel({
    super.key,
    required this.url,
    required this.token,
    required this.enabled,
    required this.ownsIntent,
    required this.clientBuilder,
    required this.confirmCleartext,
    this.browserOrigin,
  });

  final TextEditingController url;
  final TextEditingController token;
  final bool enabled;
  final bool Function() ownsIntent;
  final HermesApiClient Function(HermesApiConfig) clientBuilder;
  final Future<bool> Function(String) confirmCleartext;
  final String? browserOrigin;

  @override
  State<ConnectionCheckPanel> createState() => _ConnectionCheckPanelState();
}

class _ConnectionCheckPanelState extends State<ConnectionCheckPanel> {
  int _generation = 0;
  bool _pending = false;
  bool _inFlight = false;
  String? _notice;
  String _urlText = '';
  String _tokenText = '';

  @override
  void initState() {
    super.initState();
    _urlText = widget.url.text;
    _tokenText = widget.token.text;
    widget.url.addListener(_fieldChanged);
    widget.token.addListener(_fieldChanged);
  }

  void _fieldChanged() {
    if (_urlText == widget.url.text && _tokenText == widget.token.text) return;
    _urlText = widget.url.text;
    _tokenText = widget.token.text;
    _invalidate();
  }

  void _invalidate() {
    _generation++;
    setState(() {
      _pending = false;
      _notice = null;
    });
  }

  @override
  void didUpdateWidget(ConnectionCheckPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.token != widget.token) {
      oldWidget.url.removeListener(_fieldChanged);
      oldWidget.token.removeListener(_fieldChanged);
      _urlText = widget.url.text;
      _tokenText = widget.token.text;
      widget.url.addListener(_fieldChanged);
      widget.token.addListener(_fieldChanged);
      _generation++;
      _pending = false;
      _notice = null;
    }
    if (!widget.enabled || !widget.ownsIntent()) {
      _generation++;
      _pending = false;
      _notice = null;
    }
  }

  Future<void> _test() async {
    if (_inFlight || !widget.enabled || !widget.ownsIntent()) return;
    final generation = ++_generation;
    final strings = AppLocalizations.of(context);
    bool owns() =>
        mounted &&
        generation == _generation &&
        widget.enabled &&
        widget.ownsIntent();
    setState(() {
      _pending = true;
      _inFlight = true;
      _notice = null;
    });
    try {
      final uri = Uri.parse(widget.url.text.trim());
      if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
        throw ArgumentError('Invalid endpoint');
      }
      final config = HermesApiConfig.fromBaseUrl(
        uri.toString(),
        apiKey: widget.token.text.trim(),
      );
      if (hermesEndpointRequiresCleartextCredentialWarning(
        config.baseUri.toString(),
        apiKey: config.apiKey,
      )) {
        if (!await widget.confirmCleartext(config.baseUri.toString()) ||
            !owns()) {
          return;
        }
      }
      if (!owns()) return;
      final document = await widget
          .clientBuilder(config)
          .capabilities()
          .timeout(const Duration(seconds: 20));
      if (!owns()) return;
      if (!document.supportsSchema ||
          document.object != 'hermes.api_server.capabilities' ||
          document.platform != 'hermes-agent') {
        throw const FormatException('Unsupported discovery');
      }
      setState(
        () => _notice = HermesTransportPolicy(document).supportsAnyChatTransport
            ? strings.connectionCheckVerified
            : strings.connectionCheckUnsupported,
      );
    } catch (error) {
      if (!owns()) return;
      final String notice;
      if (error is HermesApiStatusException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        notice = strings.connectionCheckDenied;
      } else if (error is ArgumentError) {
        notice = strings.connectionCheckInvalid;
      } else if (error is FormatException) {
        notice = strings.connectionCheckIncompatible;
      } else if (error is TimeoutException ||
          error is HermesApiTransportException &&
              error.kind == HermesApiTransportFailureKind.timeout) {
        notice = strings.connectionCheckTimeout;
      } else if (error is HermesApiTransportException &&
          error.kind == HermesApiTransportFailureKind.tls) {
        notice = strings.connectionCheckTls;
      } else {
        notice = widget.browserOrigin != null
            ? strings.connectionCheckBrowserNetwork
            : strings.connectionCheckNetwork;
      }
      setState(() => _notice = notice);
    } finally {
      if (mounted) {
        setState(() {
          _inFlight = false;
          if (generation == _generation) {
            _pending = false;
            if (!widget.ownsIntent()) _notice = null;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    widget.url.removeListener(_fieldChanged);
    widget.token.removeListener(_fieldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConnectionSetupGuide(browserOrigin: widget.browserOrigin),
        if (widget.browserOrigin != null) ...[
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: strings.connectionBrowserOrigin(widget.browserOrigin!),
            excludeSemantics: true,
            child: SelectableText(
              strings.connectionBrowserOrigin(widget.browserOrigin!),
            ),
          ),
          Text(strings.connectionBrowserOriginHelp),
        ],
        const SizedBox(height: 8),
        Text(
          strings.connectionCheckBoundary,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('connection-check-button'),
          onPressed:
              widget.enabled && widget.url.text.trim().isNotEmpty && !_inFlight
              ? _test
              : null,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(strings.connectionCheckAction),
        ),
        if (_pending) ...[
          const LinearProgressIndicator(),
          TextButton(
            key: const ValueKey('connection-check-cancel'),
            onPressed: _invalidate,
            child: Text(strings.connectionCheckCancel),
          ),
        ],
        if (_notice != null && widget.ownsIntent())
          Semantics(
            liveRegion: true,
            child: Text(
              _notice!,
              key: const ValueKey('connection-check-result'),
            ),
          ),
        if (_notice == strings.connectionCheckDenied && widget.ownsIntent())
          TextButton.icon(
            key: const ValueKey('connection-check-access-help'),
            onPressed: () => showConnectionAccessHelp(context),
            icon: const Icon(Icons.help_outline),
            label: Text(strings.connectionAccessTitle),
          ),
      ],
    );
  }
}
