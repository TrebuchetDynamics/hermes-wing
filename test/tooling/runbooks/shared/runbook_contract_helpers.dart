import 'package:flutter_test/flutter_test.dart';

import '../../shared/file_contract_helpers.dart';

const androidDeviceAndSecretContractsRunbook =
    'docs/runbooks/shared/android-device-and-secret-contracts.md';

String readRunbookContractWithSharedPolicy(String runbookPath) {
  return readRequiredFiles([
    runbookPath,
    androidDeviceAndSecretContractsRunbook,
  ]);
}

void expectRunbookContainsAll(String text, Iterable<String> snippets) {
  for (final snippet in snippets) {
    expect(text, contains(snippet));
  }
}

void expectRunbookOmitsAll(String text, Iterable<String> snippets) {
  for (final snippet in snippets) {
    expect(text, isNot(contains(snippet)));
  }
}

void expectRunbookHasNoSecretPlaceholders(String text) {
  expectNoSecretPlaceholders(text);
}
