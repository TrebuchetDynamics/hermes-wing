part of '../../parser.dart';

SetupQrImageImport? _bestCorePairingDescriptorImport(
  Iterable<_SharedTextCoreDescriptorCandidate> coreDescriptors,
) {
  return _bestConnectionImportCandidate(
    coreDescriptors
        .map(
          (coreDescriptor) => _connectionImportCandidateFromCoreDescriptor(
            coreDescriptor.payload,
          ),
        )
        .whereType<_ConnectionImportCandidate>(),
  )?.toImport();
}

SetupQrImageImport? _parseCorePairingDescriptorPayload(String text) {
  return _connectionImportCandidateFromCoreDescriptor(text)?.toImport();
}

_ConnectionImportCandidate? _connectionImportCandidateFromCoreDescriptor(
  String text,
) {
  final uri = Uri.tryParse(text);
  if (uri == null || !_isCorePairingDescriptorUri(uri)) return null;
  try {
    final descriptor = NavivoxPairingDescriptor.parse(text);
    return _ConnectionImportCandidate(
      baseUrl: descriptor.baseUri.toString(),
      token: descriptor.token,
      webSocketUrl: descriptor.webSocketUri.toString(),
      serverId: descriptor.serverId,
      profileId: descriptor.profileId,
    );
  } on FormatException {
    return null;
  }
}

Iterable<_SharedTextCoreDescriptorCandidate>
_corePairingDescriptorCandidatesFromSharedText(String text) sync* {
  for (final match in _corePairingDescriptorUriPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    yield _SharedTextCoreDescriptorCandidate(
      payload: _trimCopiedEndpointUrl(matchedText),
      sourceWindow: _TextWindow(start: match.start, end: match.end),
    );
  }
}

class _SharedTextCoreDescriptorCandidate {
  const _SharedTextCoreDescriptorCandidate({
    required this.payload,
    required this.sourceWindow,
  });

  final String payload;
  final _TextWindow sourceWindow;
}

String _sharedTextWithoutMalformedCoreDescriptors(
  String text,
  Iterable<_SharedTextCoreDescriptorCandidate> coreDescriptors,
) {
  final characters = text.split('');
  for (final descriptor in coreDescriptors) {
    if (_parseCorePairingDescriptorPayload(descriptor.payload) != null) {
      continue;
    }
    for (
      var index = descriptor.sourceWindow.start;
      index < descriptor.sourceWindow.end;
      index++
    ) {
      characters[index] = ' ';
    }
  }
  return characters.join();
}

final _corePairingDescriptorUriPattern = RegExp(
  r'\bnavivox://connect(?:\?\S*)?',
  caseSensitive: false,
);
