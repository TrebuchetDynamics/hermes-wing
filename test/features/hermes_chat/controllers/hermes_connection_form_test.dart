import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/controllers/hermes_connection_form.dart';

void main() {
  late HermesConnectionForm form;

  setUp(() {
    form = HermesConnectionForm(
      normalizeBaseUrl: hermesPublicEndpointBaseUrl,
      sanitizeLabel: (value) => value,
    );
    addTearDown(form.dispose);
  });

  HermesConnectionAttempt attemptFor(String baseUrl, {String? apiKey}) =>
      form.beginAttempt(baseUrl: baseUrl, apiKey: apiKey);

  group('attempt staleness', () {
    test('an untouched form keeps its attempt current', () {
      form.baseUrl.text = 'https://a.example';
      final attempt = attemptFor('https://a.example');

      expect(form.isStale(attempt), isFalse);
    });

    test('a newer attempt supersedes the older one', () {
      form.baseUrl.text = 'https://a.example';
      final first = attemptFor('https://a.example');
      final second = attemptFor('https://a.example');

      expect(form.isStale(first), isTrue);
      expect(form.isStale(second), isFalse);
    });

    test('abandonAttempt supersedes without opening a new attempt', () {
      form.baseUrl.text = 'https://a.example';
      final attempt = attemptFor('https://a.example');

      form.abandonAttempt();

      expect(form.isStale(attempt), isTrue);
    });

    test('editing the origin mid-connect abandons the result', () {
      form.baseUrl.text = 'https://a.example';
      final attempt = attemptFor('https://a.example');

      form.baseUrl.text = 'https://b.example';

      expect(form.isStale(attempt), isTrue);
    });

    test('editing the credential mid-connect abandons the result', () {
      form.baseUrl.text = 'https://a.example';
      form.apiKey.text = 'first-secret';
      final attempt = attemptFor('https://a.example', apiKey: 'first-secret');

      form.apiKey.text = 'second-secret';

      expect(form.isStale(attempt), isTrue);
    });

    test('editing the label mid-connect abandons the result', () {
      form.baseUrl.text = 'https://a.example';
      form.label.text = 'Work';
      final attempt = attemptFor('https://a.example');

      form.label.text = 'Home';

      expect(form.isStale(attempt), isTrue);
    });

    test('a cosmetic origin edit that normalizes the same stays current', () {
      form.baseUrl.text = 'https://a.example';
      final attempt = attemptFor('https://a.example');

      form.baseUrl.text = '  https://a.example/  ';

      expect(
        form.isStale(attempt),
        isFalse,
        reason: 'staleness compares normalized origins, not raw text',
      );
    });

    test('blank and absent credentials are the same intent', () {
      form.baseUrl.text = 'https://a.example';
      final attempt = attemptFor('https://a.example');

      expect(attempt.apiKey, isNull);
      expect(form.isStale(attempt), isFalse);

      form.apiKey.text = '   ';
      expect(
        form.isStale(attempt),
        isFalse,
        reason: 'whitespace is not a credential',
      );
    });
  });

  group('stored values', () {
    test('blank credential and label are stored as absent', () {
      form.baseUrl.text = 'https://a.example';
      final attempt = attemptFor('https://a.example', apiKey: '   ');

      expect(attempt.storedApiKey, isNull);
      expect(attempt.storedLabel, isNull);
    });

    test('present credential and label survive trimming', () {
      form.baseUrl.text = 'https://a.example';
      form.label.text = '  Work  ';
      final attempt = attemptFor('https://a.example', apiKey: '  secret  ');

      expect(attempt.storedApiKey, 'secret');
      expect(attempt.storedLabel, 'Work');
    });

    test('the attempt records the normalized origin', () {
      final attempt = attemptFor('https://a.example/private?token=discarded');

      expect(attempt.baseUrl, 'https://a.example');
    });
  });

  group('field management', () {
    test('read intent generation remembers edits and explicit actions', () {
      var generation = form.intentGeneration;
      for (final field in [form.baseUrl, form.apiKey, form.label]) {
        field.text = 'Synthetic value';
        field.clear();
        expect(form.intentGeneration, greaterThan(generation));
        generation = form.intentGeneration;
      }
      form.clear();
      expect(form.intentGeneration, greaterThan(generation));
      generation = form.intentGeneration;
      form.applyProfile(baseUrl: '');
      expect(form.intentGeneration, greaterThan(generation));
      generation = form.intentGeneration;
      form.beginAttempt(baseUrl: '');
      expect(form.intentGeneration, greaterThan(generation));
      generation = form.intentGeneration;
      form.abandonAttempt();
      expect(form.intentGeneration, greaterThan(generation));
    });

    test('selection and masking do not invalidate read intent', () {
      form.baseUrl.text = 'https://example.invalid';
      final generation = form.intentGeneration;
      form.baseUrl.selection = const TextSelection.collapsed(offset: 0);
      form.toggleApiKeyVisibility();
      expect(form.intentGeneration, generation);
    });

    test('saved autofill intent remembers text edit and return', () {
      expect(form.hasFieldIntent, isFalse);
      form.label.text = 'Manual label';
      form.label.clear();
      expect(form.hasFieldIntent, isTrue);
    });

    test('same-value preset and saved selection establish field intent', () {
      form.clear(keepBaseUrl: '');
      expect(form.hasFieldIntent, isTrue);
      final pristine = HermesConnectionForm(
        normalizeBaseUrl: hermesPublicEndpointBaseUrl,
        sanitizeLabel: (value) => value,
      );
      addTearDown(pristine.dispose);
      pristine.applyProfile(baseUrl: '');
      expect(pristine.hasFieldIntent, isTrue);
    });

    test('selection and masking alone leave saved autofill pristine', () {
      final pristine = HermesConnectionForm(
        normalizeBaseUrl: hermesPublicEndpointBaseUrl,
        sanitizeLabel: (value) => value,
        initialBaseUrl: 'https://saved.invalid',
      );
      addTearDown(pristine.dispose);
      pristine.baseUrl.selection = const TextSelection.collapsed(offset: 0);
      pristine.toggleApiKeyVisibility();
      expect(pristine.hasFieldIntent, isFalse);
    });

    test('applyProfile fills every field', () {
      form.applyProfile(
        baseUrl: 'https://a.example',
        apiKey: 'secret',
        label: 'Work',
      );

      expect(form.baseUrl.text, 'https://a.example');
      expect(form.apiKey.text, 'secret');
      expect(form.label.text, 'Work');
    });

    test('applyProfile blanks a profile without credential or label', () {
      form.applyProfile(baseUrl: 'https://a.example', apiKey: 'stale');
      form.applyProfile(baseUrl: 'https://b.example');

      expect(form.apiKey.text, isEmpty);
      expect(form.label.text, isEmpty);
    });

    test('clear empties everything, optionally keeping the origin', () {
      form.applyProfile(
        baseUrl: 'https://a.example',
        apiKey: 'secret',
        label: 'Work',
      );

      form.clear(keepBaseUrl: 'https://b.example');
      expect(form.baseUrl.text, 'https://b.example');
      expect(form.apiKey.text, isEmpty);
      expect(form.label.text, isEmpty);

      form.clear();
      expect(form.baseUrl.text, isEmpty);
    });

    test('credential masking toggles and notifies', () {
      var notifications = 0;
      form.addListener(() => notifications++);

      expect(form.obscureApiKey, isTrue);
      form.toggleApiKeyVisibility();

      expect(form.obscureApiKey, isFalse);
      expect(notifications, 1);
    });
  });

  test('the label sanitizer is applied to attempts', () {
    final redacting = HermesConnectionForm(
      normalizeBaseUrl: hermesPublicEndpointBaseUrl,
      sanitizeLabel: (value) => value.replaceAll('secret', '[redacted]'),
    );
    addTearDown(redacting.dispose);
    redacting.label.text = 'my secret box';

    final attempt = redacting.beginAttempt(baseUrl: 'https://a.example');

    expect(attempt.label, 'my [redacted] box');
  });
}
