/// Token class for Malsami G2P engine
///
/// This is the Dart implementation of the Python MToken class
class MToken {
  /// The text content of the token
  final String text;

  /// Part-of-speech tag
  final String tag;

  /// Whitespace following the token
  final String whitespace;

  /// Phonetic representation
  final String? phonemes;

  /// Start timestamp (if applicable)
  final double? startTs;

  /// End timestamp (if applicable)
  final double? endTs;

  /// Underscore properties (metadata)
  final Underscore? underscore;

  /// Constructor for MToken
  const MToken({
    required this.text,
    required this.tag,
    required this.whitespace,
    this.phonemes,
    this.startTs,
    this.endTs,
    this.underscore,
  });

  // We don't need the underscore getter since we're accessing the underscore property directly

  /// Creates a copy of this token with the specified fields replaced
  MToken copyWith({
    String? text,
    String? tag,
    String? whitespace,
    String? phonemes,
    double? startTs,
    double? endTs,
    Underscore? underscore,
  }) {
    return MToken(
      text: text ?? this.text,
      tag: tag ?? this.tag,
      whitespace: whitespace ?? this.whitespace,
      phonemes: phonemes ?? this.phonemes,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      underscore: underscore ?? this.underscore,
    );
  }
}

/// Underscore class for token metadata
///
/// This is the Dart implementation of the Python MToken.Underscore class
class Underscore {
  /// Whether this token is the head of a phrase
  final bool? isHead;

  /// Alias for this token (if any)
  final String? alias;

  /// Stress level for this token
  final double? stress;

  /// Currency symbol (if applicable)
  final String? currency;

  /// Number flags
  final String? numFlags;

  /// Whether there should be a space before this token
  final bool? prespace;

  /// Rating for this token (if applicable)
  final int? rating;

  /// Constructor for Underscore
  const Underscore({
    this.isHead,
    this.alias,
    this.stress,
    this.currency,
    this.numFlags,
    this.prespace,
    this.rating,
  });

  /// Creates a copy of this underscore with the specified fields replaced
  Underscore copyWith({
    bool? isHead,
    String? alias,
    double? stress,
    String? currency,
    String? numFlags,
    bool? prespace,
    int? rating,
  }) {
    return Underscore(
      isHead: isHead ?? this.isHead,
      alias: alias ?? this.alias,
      stress: stress ?? this.stress,
      currency: currency ?? this.currency,
      numFlags: numFlags ?? this.numFlags,
      prespace: prespace ?? this.prespace,
      rating: rating ?? this.rating,
    );
  }
}
