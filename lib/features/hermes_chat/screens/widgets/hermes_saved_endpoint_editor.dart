part of '../hermes_chat_screen.dart';

/// A local repair draft, deliberately independent of the active channel/form.
class _SavedEndpointEditor extends StatefulWidget {
  const _SavedEndpointEditor({
    required this.profile,
    required this.ownsIntent,
    required this.clientBuilder,
    required this.confirmCleartext,
    required this.save,
  });
  final HermesEndpointConfig profile;
  final bool Function() ownsIntent;
  final HermesApiClient Function(HermesApiConfig) clientBuilder;
  final Future<bool> Function(String) confirmCleartext;
  final Future<void> Function(String, String?) save;
  @override
  State<_SavedEndpointEditor> createState() => _SavedEndpointEditorState();
}

class _SavedEndpointEditorState extends State<_SavedEndpointEditor> {
  late final _url = TextEditingController(text: widget.profile.baseUrl);
  final _key = TextEditingController();
  bool _removeKey = false;
  bool _testing = false;
  bool _saving = false;
  int _generation = 0;
  String? _notice;
  bool get _owns => mounted && widget.ownsIntent();

  @override
  void initState() {
    super.initState();
    _url.addListener(_changed);
    _key.addListener(_changed);
  }

  void _changed() {
    setState(() {
      _generation++;
      _testing = false;
      _notice = null;
    });
  }

  HermesApiConfig _draft() {
    final raw = _url.text.trim();
    final url = hermesPublicEndpointBaseUrl(raw);
    // Reject secret-bearing or silently discarded URL components.
    final uri = Uri.parse(raw);
    if (uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty &&
            uri.path != '/' &&
            uri.path != Uri.parse(url).path)) {
      throw const FormatException('Use a plain Agent endpoint.');
    }
    final key = _key.text.trim();
    return HermesApiConfig.fromBaseUrl(
      url,
      apiKey: _removeKey
          ? null
          : key.isNotEmpty
          ? key
          : url == widget.profile.baseUrl
          ? widget.profile.apiKey
          : null,
    );
  }

  Future<void> _test() async {
    final strings = AppLocalizations.of(context);
    if (!_owns) {
      setState(() => _notice = strings.chatSavedEndpointStale);
      return;
    }
    final generation = ++_generation;
    setState(() {
      _testing = true;
      _notice = null;
    });
    bool ownsRead() => _owns && generation == _generation;
    try {
      final draft = _draft();
      if (hermesEndpointRequiresCleartextCredentialWarning(
        draft.baseUri.toString(),
        apiKey: draft.apiKey,
      )) {
        if (!await widget.confirmCleartext(draft.baseUri.toString())) {
          if (ownsRead()) {
            setState(() {
              _testing = false;
              _notice = strings.chatSavedEndpointTestCancelled;
            });
          }
          return;
        }
      }
      if (!ownsRead()) return;
      // Exactly one direct, read-only discovery request. Never connect a channel.
      final document = await widget
          .clientBuilder(draft)
          .capabilities()
          .timeout(const Duration(seconds: 20));
      if (!document.supportsSchema ||
          document.object != 'hermes.api_server.capabilities' ||
          document.platform != 'hermes-agent') {
        throw const FormatException('Unsupported capability document.');
      }
      if (ownsRead()) {
        setState(() => _notice = strings.chatSavedEndpointTestSuccess);
      }
    } catch (error) {
      if (ownsRead()) {
        setState(
          () => _notice =
              error is HermesApiStatusException &&
                  (error.statusCode == 401 || error.statusCode == 403)
              ? strings.chatSavedEndpointTestDenied
              : strings.chatSavedEndpointTestFailed,
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _testing = false;
          if (!widget.ownsIntent()) _notice = strings.chatSavedEndpointStale;
        });
      }
    }
  }

  Future<void> _save() async {
    final strings = AppLocalizations.of(context);
    if (!_owns) {
      setState(() => _notice = strings.chatSavedEndpointStale);
      return;
    }
    _generation++;
    setState(() {
      _saving = true;
      _testing = false;
      _notice = null;
    });
    try {
      final draft = _draft();
      await widget.save(draft.baseUri.toString(), draft.apiKey);
      if (!mounted || !widget.ownsIntent()) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(strings.chatSavedEndpointSaved)));
    } catch (_) {
      if (_owns) setState(() => _notice = strings.chatSavedEndpointSaveFailed);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          if (!widget.ownsIntent()) _notice = strings.chatSavedEndpointStale;
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        key: const ValueKey('hermes-saved-edit-dialog'),
        title: Text(strings.chatSavedEndpointEdit),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.chatSavedEndpointEditBody),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('hermes-saved-edit-url'),
                  controller: _url,
                  autofocus: true,
                  enabled: !_saving,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  decoration: InputDecoration(
                    labelText: strings.chatLayoutServerUrlLabel,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('hermes-saved-edit-key'),
                  controller: _key,
                  enabled: !_saving && !_removeKey,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  decoration: InputDecoration(
                    labelText: strings.chatSavedEndpointReplacementKey,
                  ),
                ),
                const SizedBox(height: 8),
                _SavedEndpointReadableText(
                  key: const ValueKey('hermes-saved-edit-help'),
                  text: strings.chatSavedEndpointKeyHelp,
                ),
                CheckboxListTile(
                  key: const ValueKey('hermes-saved-edit-remove-key'),
                  value: _removeKey,
                  title: Text(strings.chatSavedEndpointRemoveKey),
                  contentPadding: EdgeInsets.zero,
                  onChanged: _saving
                      ? null
                      : (value) {
                          _removeKey = value ?? false;
                          _changed();
                        },
                ),
                if (_testing || _saving) const LinearProgressIndicator(),
                if (_notice != null)
                  Semantics(
                    liveRegion: true,
                    child: _SavedEndpointReadableText(
                      key: ValueKey(_notice),
                      text: _notice!,
                      autofocus: true,
                      textKey: const ValueKey('hermes-saved-edit-notice'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-saved-edit-cancel'),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(strings.cancelAction),
          ),
          if (_testing)
            TextButton(
              key: const ValueKey('hermes-saved-edit-cancel-test'),
              onPressed: () {
                _generation++;
                setState(() {
                  _testing = false;
                  _notice = strings.chatSavedEndpointTestCancelled;
                });
              },
              child: Text(strings.chatSavedEndpointCancelTest),
            )
          else
            OutlinedButton(
              key: const ValueKey('hermes-saved-edit-test'),
              onPressed: _saving ? null : _test,
              child: Text(strings.chatSavedEndpointTest),
            ),
          FilledButton(
            key: const ValueKey('hermes-saved-edit-save'),
            onPressed: _saving ? null : _save,
            child: Text(strings.saveAction),
          ),
        ],
      ),
    );
  }
}

/// Guidance and outcomes are keyboard stops, not clipped field decorations.
class _SavedEndpointReadableText extends StatefulWidget {
  const _SavedEndpointReadableText({
    super.key,
    required this.text,
    this.autofocus = false,
    this.textKey,
  });
  final String text;
  final bool autofocus;
  final Key? textKey;

  @override
  State<_SavedEndpointReadableText> createState() =>
      _SavedEndpointReadableTextState();
}

class _SavedEndpointReadableTextState
    extends State<_SavedEndpointReadableText> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    onFocusChange: (focused) {
      setState(() => _focused = focused);
      if (focused) {
        // Wait for the newly published outcome's layout before revealing it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focused) Scrollable.ensureVisible(context);
        });
      }
    },
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _focused
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(widget.text, key: widget.textKey),
      ),
    ),
  );
}
