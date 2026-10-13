import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations_en.dart';

bool _offersLegacyManagement(String copy) => RegExp(
  r'wing[ -]?link|re-pair|scan.*qr',
  caseSensitive: false,
).hasMatch(copy);

void main() {
  final retired = RegExp(
    r'^(managedByWingLink|gatewayManagementIndependent|directoryBrowser\w*|gatewayTrust\w*|profileApproval\w*|profileDeletionApprovalExpired|profileRetryApproved\w*|profileCancelSetup|enroll(?!(?:Intro|OptionalSetupAction|PhoneHelp|BackToOptions|LinuxHelp|Title|LegacyHandoffTitle|LegacyHandoffBody|InstallOnPhoneAction)$)\w*)$',
  );

  test('retired localization input and generated API stay absent', () {
    final input =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(
      input.keys.where((key) => retired.hasMatch(key.replaceFirst('@', ''))),
      isEmpty,
    );
    for (final path in [
      'lib/l10n/app_localizations.dart',
      'lib/l10n/app_localizations_en.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        RegExp(
          r'\b(?:get|String) (\w+)',
        ).allMatches(source).map((match) => match[1]!).where(retired.hasMatch),
        isEmpty,
        reason: path,
      );
    }
  });

  test('live connection copy offers only direct Agent access', () {
    final strings = AppLocalizationsEn();
    for (final copy in [
      strings.chatSavedEndpointEditBody,
      strings.gatewayStatusConnectionRequiredBody,
      strings.chatConnectionDisconnectBody('saved Agent'),
      strings.chatLayoutConnectBody,
      strings.chatLayoutRemoteAuthExplanation,
      strings.chatLayoutCredentialBoundaryBody,
      strings.chatErrorConnectTlsBody,
      strings.settingsScanPairingQr,
      strings.chatLayoutScanQrAction,
    ]) {
      expect(_offersLegacyManagement(copy), isFalse, reason: copy);
    }
    expect(
      strings.chatSavedEndpointEditBody,
      contains('Saving does not connect'),
    );
    expect(strings.chatSavedEndpointEditBody, contains('credential'));
    expect(
      strings.enrollLegacyHandoffBody,
      contains('Existing saved connections are unchanged'),
    );
    expect(
      strings.enrollLegacyHandoffBody,
      contains('SSH, Remote or the on-phone Termux guide'),
    );
    expect(
      strings.chatLayoutRemoteAuthExplanation,
      contains('OAuth-only server cannot currently connect'),
    );
  });

  test('guard rejects legacy offers but keeps explicit rejection guidance', () {
    for (final copy in [
      'Wing Link management is available separately.',
      'A changed Agent URL drops its Wing Link association.',
      'Scan a Hermes pairing QR code',
      'Re-pair explicitly if the trusted identity changed.',
    ]) {
      expect(_offersLegacyManagement(copy), isTrue, reason: copy);
    }
    expect(
      _offersLegacyManagement('Pairing links are no longer supported'),
      isFalse,
    );
  });
}
