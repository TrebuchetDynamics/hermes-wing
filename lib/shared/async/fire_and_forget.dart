import 'dart:async';

import 'package:flutter/foundation.dart';

/// Sink for a background operation that failed with nobody awaiting it.
typedef FireAndForgetReporter = void Function(String operation, Object error);

/// Where [fireAndForget] reports failures. Swappable like [debugPrint] so tests
/// and future diagnostics can observe what would otherwise vanish.
FireAndForgetReporter reportFireAndForgetFailure = _debugReportFailure;

/// Starts [operation] without awaiting it, reporting a failure instead of
/// letting it surface as an uncaught async error.
///
/// Use this for genuinely detached work — teardown, cancellation, best-effort
/// refreshes — where the caller cannot wait and the operator has nothing to
/// decide. Prefer `await` anywhere the result changes what happens next, and a
/// visible error surface anywhere the operator should know.
///
/// This exists because `unawaited(f)` satisfies the `unawaited_futures` lint
/// while leaving a rejected `f` completely unhandled. That gap shipped real
/// defects here; naming the operation makes the swallowing searchable.
///
/// [operation] may be null so `service?.cancel()` reads naturally at teardown.
void fireAndForget(Future<void>? operation, String operationName) {
  if (operation == null) return;
  unawaited(
    operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace _) {
        reportFireAndForgetFailure(operationName, error);
      },
    ),
  );
}

void _debugReportFailure(String operation, Object error) {
  // Only the operation label and the error type. An error message can carry an
  // endpoint URL, bearer token, or transcript, and none of those may be logged.
  debugPrint('Hermes Wing: $operation failed (${error.runtimeType})');
}
