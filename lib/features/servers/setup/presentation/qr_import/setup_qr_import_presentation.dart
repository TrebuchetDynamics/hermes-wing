import '../../../models/connection_import.dart';
import '../../../shared/connection_import_parser.dart';

export '../../../shared/connection_import_parser.dart';

class SetupQrImportPresentation extends ConnectionImportParser {
  const SetupQrImportPresentation();
}

SetupQrImageImport? parseNavivoxQrPayload(String payload) =>
    parseNavivoxConnectionImportPayload(payload);
