import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../ffi/cactus.dart' as cactus;

class NeedleEngineException implements Exception {
  const NeedleEngineException(this.message);

  final String message;

  @override
  String toString() => 'NeedleEngineException: $message';
}

abstract interface class NeedleEngineApi {
  bool get isLoaded;
  Future<void> load(String modelDir);
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  });
  Future<void> unload();
}

/// Serializes async operations in submission order. Native engine calls
/// must never overlap: thread-safety of the engine is unknown, and
/// unload() must not destroy a handle another isolate is still using.
class NativeCallQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

/// Real FFI engine. Blocking native calls run via [Isolate.run]; the model
/// handle crosses isolates as a raw address (native heap is process-wide).
/// Every op passes through a [NativeCallQueue] so ops execute strictly in
/// submission order: concurrent loads dedupe, and unload waits for any
/// in-flight complete before destroying the handle.
class NeedleEngine implements NeedleEngineApi {
  final NativeCallQueue _queue = NativeCallQueue();
  int? _modelAddress;

  @override
  bool get isLoaded => _modelAddress != null;

  @override
  Future<void> load(String modelDir) {
    return _queue.run(() async {
      // Checked inside the queued op so concurrent loads dedupe instead of
      // both running cactus_init and leaking a handle.
      if (_modelAddress != null) return;
      final address = await Isolate.run(() => _initSync(modelDir));
      if (address == 0) {
        throw NeedleEngineException('cactus_init returned null for $modelDir');
      }
      _modelAddress = address;
    });
  }

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) {
    return _queue.run(() {
      // Checked inside the queued op: a queued complete may legitimately
      // run after a queued unload, and must then fail instead of touching
      // a destroyed handle.
      final address = _modelAddress;
      if (address == null) {
        throw const NeedleEngineException('Model is not loaded.');
      }
      return Isolate.run(
        () => _completeSync(address, messagesJson, toolsJson, optionsJson),
      );
    });
  }

  @override
  Future<void> unload() {
    return _queue.run(() async {
      final address = _modelAddress;
      _modelAddress = null;
      if (address != null) {
        await Isolate.run(() => _destroySync(address));
      }
    });
  }
}

const _responseBufferBytes = 64 * 1024;

/// The Cactus engine enables cloud telemetry (device id, timings, error
/// strings to a third-party endpoint) by default inside cactus_init.
/// It honors this env-var kill switch, applied via libc setenv before init.
/// See spike findings: evaluation must stay fully on-device.
void _disableCloudTelemetry() {
  final setenv = DynamicLibrary.process()
      .lookupFunction<
        Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        int Function(Pointer<Utf8>, Pointer<Utf8>, int)
      >('setenv');
  final name = 'CACTUS_NO_CLOUD_TELE'.toNativeUtf8();
  final value = '1'.toNativeUtf8();
  try {
    setenv(name, value, 1);
  } finally {
    calloc.free(name);
    calloc.free(value);
  }
}

int _initSync(String modelDir) {
  _disableCloudTelemetry();
  final path = modelDir.toNativeUtf8();
  try {
    return cactus.cactusInit(path, nullptr, false).address;
  } finally {
    calloc.free(path);
  }
}

String _completeSync(
  int modelAddress,
  String messagesJson,
  String toolsJson,
  String optionsJson,
) {
  final model = Pointer<Void>.fromAddress(modelAddress);
  final messages = messagesJson.toNativeUtf8();
  final tools = toolsJson.toNativeUtf8();
  final options = optionsJson.toNativeUtf8();
  final buffer = calloc<Uint8>(_responseBufferBytes);
  try {
    final written = cactus.cactusComplete(
      model,
      messages,
      buffer.cast<Utf8>(),
      _responseBufferBytes,
      options,
      tools,
      nullptr,
      nullptr,
      nullptr,
      0,
    );
    if (written < 0) {
      throw NeedleEngineException(
        'cactus_complete failed: status $written${_lastErrorSuffix()}',
      );
    }
    if (written >= _responseBufferBytes) {
      throw NeedleEngineException(
        'cactus_complete response truncated '
        '($written bytes; buffer $_responseBufferBytes)',
      );
    }
    return buffer.cast<Utf8>().toDartString(length: written);
  } finally {
    calloc.free(messages);
    calloc.free(tools);
    calloc.free(options);
    calloc.free(buffer);
  }
}

void _destroySync(int modelAddress) {
  cactus.cactusDestroy(Pointer<Void>.fromAddress(modelAddress));
}

/// Formats `cactus_get_last_error` as an exception-message suffix, or ''
/// when there is no error text. Only called on the isolate that just made
/// the failing native call.
String _lastErrorSuffix() {
  final error = cactus.cactusGetLastError();
  if (error == nullptr) return '';
  final text = error.toDartString();
  return text.isEmpty ? '' : ' ($text)';
}
