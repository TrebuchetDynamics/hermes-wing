part of '../../parser.dart';

enum _CopiedUriPayloadRejectionReason {
  copiedTextSeparator,
  attachedTokenLabel,
  invalidOrUnsupportedUri,
}

class _CopiedUriPayloadScan {
  const _CopiedUriPayloadScan._({this.payload, this.rejectionReason});

  const _CopiedUriPayloadScan.accepted(_CopiedUriPayload payload)
    : this._(payload: payload);

  const _CopiedUriPayloadScan.rejected(_CopiedUriPayloadRejectionReason reason)
    : this._(rejectionReason: reason);

  factory _CopiedUriPayloadScan.fromText(String text) {
    final copiedUrl = _trimCopiedEndpointUrl(text);
    if (_containsCopiedTextSeparator(copiedUrl)) {
      return const _CopiedUriPayloadScan.rejected(
        _CopiedUriPayloadRejectionReason.copiedTextSeparator,
      );
    }
    if (_hasAttachedTokenLabelAfterCopiedEndpoint(copiedUrl)) {
      return const _CopiedUriPayloadScan.rejected(
        _CopiedUriPayloadRejectionReason.attachedTokenLabel,
      );
    }
    final uri = Uri.tryParse(copiedUrl);
    if (uri == null || !uri.hasScheme) {
      return const _CopiedUriPayloadScan.rejected(
        _CopiedUriPayloadRejectionReason.invalidOrUnsupportedUri,
      );
    }
    return _CopiedUriPayloadScan.accepted(
      _CopiedUriPayload(text: copiedUrl, uri: uri),
    );
  }

  final _CopiedUriPayload? payload;
  final _CopiedUriPayloadRejectionReason? rejectionReason;

  bool get accepted => payload != null;
}

class _CopiedUriPayload {
  const _CopiedUriPayload({required this.text, required this.uri});

  final String text;
  final Uri uri;
}

_CopiedUriPayload? _copiedUriPayload(String text) =>
    _CopiedUriPayloadScan.fromText(text).payload;
