import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'durable_credential_store.dart';
import 'secure_storage_credential_store.dart';

final durableCredentialStoreProvider = Provider<DurableCredentialStore>(
  (_) => const SecureStorageDurableCredentialStore(),
);
