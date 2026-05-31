enum PairingHandoffManualEdit { address, port, token }

bool pairingHandoffManualEditClearsImportedTarget(
  PairingHandoffManualEdit edit,
) {
  return switch (edit) {
    PairingHandoffManualEdit.address || PairingHandoffManualEdit.port => true,
    PairingHandoffManualEdit.token => false,
  };
}
