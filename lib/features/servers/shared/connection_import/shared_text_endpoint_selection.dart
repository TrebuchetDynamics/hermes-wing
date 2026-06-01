part of 'parser.dart';

class _SharedTextEndpointCandidate {
  const _SharedTextEndpointCandidate({
    required this.candidate,
    required this.tokenSearchStart,
    required this.tokenSearchEnd,
    required this.leadingTokenSearchEnd,
    required this.hasFollowingToken,
    required this.canUseLeadingToken,
    required this.hasConnectionPath,
  }) : assert(tokenSearchStart >= 0),
       assert(tokenSearchEnd >= tokenSearchStart),
       assert(leadingTokenSearchEnd >= 0);

  final _ConnectionImportCandidate candidate;
  final int tokenSearchStart;
  final int tokenSearchEnd;
  final int leadingTokenSearchEnd;
  final bool hasFollowingToken;
  final bool canUseLeadingToken;
  final bool hasConnectionPath;

  _SharedTextTokenProvenance get tokenProvenance {
    return _SharedTextTokenProvenance(
      hasSelectedEndpoint: true,
      followingSearchStart: tokenSearchStart,
      followingSearchEnd: tokenSearchEnd,
      leadingSearchEnd: canUseLeadingToken ? leadingTokenSearchEnd : 0,
    );
  }

  bool isRicherThan(_SharedTextEndpointCandidate? other) {
    if (other == null) return true;
    return _SharedTextEndpointSelectionSignals.fromCandidate(
      this,
    ).isPreferredOver(_SharedTextEndpointSelectionSignals.fromCandidate(other));
  }
}

class _SharedTextEndpointSelectionSignals {
  const _SharedTextEndpointSelectionSignals({
    required this.rank,
    required this.hasFollowingToken,
    required this.hasConnectionPath,
  });

  factory _SharedTextEndpointSelectionSignals.fromCandidate(
    _SharedTextEndpointCandidate candidate,
  ) {
    return _SharedTextEndpointSelectionSignals(
      rank: candidate.candidate.rank,
      hasFollowingToken: candidate.hasFollowingToken,
      hasConnectionPath: candidate.hasConnectionPath,
    );
  }

  final _ConnectionImportCandidateRank rank;
  final bool hasFollowingToken;
  final bool hasConnectionPath;

  bool isPreferredOver(_SharedTextEndpointSelectionSignals other) {
    // Shared text often contains documentation URLs before the actual pairing
    // handoff URL. Prefer explicit connection-route vocabulary before generic
    // richness so a stale docs query token cannot outrank the real endpoint.
    if (hasConnectionPath != other.hasConnectionPath) return hasConnectionPath;

    // When two URLs expose the same connection-route signal, bind prose tokens
    // to the URL whose following segment actually contains the token.
    if (hasFollowingToken != other.hasFollowingToken) return hasFollowingToken;

    if (rank.isRicherThan(other.rank)) return true;
    if (other.rank.isRicherThan(rank)) return false;
    return false;
  }
}

class _SharedTextTokenProvenance {
  const _SharedTextTokenProvenance({
    required this.hasSelectedEndpoint,
    required this.followingSearchStart,
    required this.followingSearchEnd,
    required this.leadingSearchEnd,
  }) : assert(followingSearchStart >= 0),
       assert(followingSearchEnd >= followingSearchStart),
       assert(leadingSearchEnd >= 0);

  const _SharedTextTokenProvenance.withoutSelectedEndpoint()
    : hasSelectedEndpoint = false,
      followingSearchStart = 0,
      followingSearchEnd = 0,
      leadingSearchEnd = 0;

  factory _SharedTextTokenProvenance.fromSelectedEndpoint(
    _SharedTextEndpointCandidate? selectedEndpoint,
  ) {
    return selectedEndpoint?.tokenProvenance ??
        const _SharedTextTokenProvenance.withoutSelectedEndpoint();
  }

  final bool hasSelectedEndpoint;
  final int followingSearchStart;
  final int followingSearchEnd;
  final int leadingSearchEnd;

  String? firstToken(String text) {
    if (!hasSelectedEndpoint) return _firstToken(text);

    // Keep token provenance aligned with the selected URL candidate. Tokens
    // after the selected URL are more likely to describe that endpoint than
    // stale prose tokens copied earlier in the share text. Preserve older
    // token-before-URL imports without borrowing tokens from later URL windows.
    return _firstToken(
          text,
          start: followingSearchStart,
          end: followingSearchEnd,
        ) ??
        _lastToken(text, end: leadingSearchEnd);
  }
}
