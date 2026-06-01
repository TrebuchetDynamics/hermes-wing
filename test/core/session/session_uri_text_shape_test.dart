import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/session_uri_text_shape.dart';

void main() {
  group('saved session URI text syntax', () {
    test('exposes bracketed host literals before URI parser scheme checks', () {
      final syntax = SavedSessionUriTextSyntax.parse('[::1]:8765/stream');

      expect(syntax.text, '[::1]:8765/stream');
      expect(syntax.startsWithBracketedHostLiteral, isTrue);
      expect(syntax.hasAuthoritySchemeSeparator, isFalse);
      expect(syntax.hasPortLikeSchemeSeparator, isFalse);
      expect(syntax.hasNonPortSchemeSeparator, isTrue);
    });

    test('does not let bracketed host compatibility hide authority URLs', () {
      final syntax = SavedSessionUriTextSyntax.parse(
        '[::1]://stream?token=secret',
      );

      expect(syntax.startsWithBracketedHostLiteral, isFalse);
      expect(syntax.hasAuthoritySchemeSeparator, isTrue);
    });

    test('exposes host-port versus named scheme separators', () {
      expect(
        SavedSessionUriTextSyntax.parse(
          'gateway.example:8765/stream',
        ).hasPortLikeSchemeSeparator,
        isTrue,
      );
      expect(
        SavedSessionUriTextSyntax.parse(
          'mailto:secret-token',
        ).hasNonPortSchemeSeparator,
        isTrue,
      );
    });

    test('exposes URI state delimiters in legacy-shaped metadata', () {
      expect(
        SavedSessionUriTextSyntax.parse(
          'gateway.example:8765/stream?token=secret',
        ).hasNonDurableUriStateDelimiter,
        isTrue,
      );
      expect(
        SavedSessionUriTextSyntax.parse(
          'gateway.example:8765/stream#handoff',
        ).hasNonDurableUriStateDelimiter,
        isTrue,
      );
      expect(
        SavedSessionUriTextSyntax.parse(
          'pairing-token@gateway.example:8765/stream',
        ).hasNonDurableUriStateDelimiter,
        isTrue,
      );
      expect(
        SavedSessionUriTextSyntax.parse(
          'gateway.example:8765/stream',
        ).hasNonDurableUriStateDelimiter,
        isFalse,
      );
    });
  });

  group('saved session URI text classification', () {
    test(
      'keeps explicit URL, named scheme, and legacy host shapes distinct',
      () {
        expect(
          classifySavedSessionUriTextShape('wss://gateway.example/stream'),
          SavedSessionUriTextShape.authorityUrl,
        );
        expect(
          classifySavedSessionUriTextShape('mailto:secret-token'),
          SavedSessionUriTextShape.namedScheme,
        );
        expect(
          classifySavedSessionUriTextShape('gateway.example:8765/stream'),
          SavedSessionUriTextShape.hostPortLike,
        );
        expect(
          classifySavedSessionUriTextShape('[::1]:8765/stream'),
          SavedSessionUriTextShape.bracketedHostLiteral,
        );
        expect(
          classifySavedSessionUriTextShape('[::1]://stream?token=secret'),
          SavedSessionUriTextShape.authorityUrl,
        );
      },
    );
  });
}
