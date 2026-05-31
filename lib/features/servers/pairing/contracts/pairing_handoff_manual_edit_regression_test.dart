import 'pairing_handoff_manual_edit.dart';

void main() {
  manualPortEditClearsImportedHandoffTarget();
  manualTokenEditPreservesImportedHandoffTarget();
}

void manualPortEditClearsImportedHandoffTarget() {
  _expect(
    pairingHandoffManualEditClearsImportedTarget(
      PairingHandoffManualEdit.port,
    ),
    'manual port edits change the connection endpoint and must clear imported handoff targets',
  );
}

void manualTokenEditPreservesImportedHandoffTarget() {
  _expect(
    !pairingHandoffManualEditClearsImportedTarget(
      PairingHandoffManualEdit.token,
    ),
    'manual token edits do not change the connection endpoint target',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
