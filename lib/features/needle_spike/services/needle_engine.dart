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

/// Real FFI engine. Blocking native calls run via [Isolate.run]; the model
/// handle crosses isolates as a raw address (native heap is process-wide).
class NeedleEngine implements NeedleEngineApi {
  int? _modelAddress;

  @override
  bool get isLoaded => _modelAddress != null;

  @override
  Future<void> load(String modelDir) async {
    if (_modelAddress != null) return;
    final address = await Isolate.run(() => _initSync(modelDir));
    if (address == 0) {
      throw NeedleEngineException('cactus_init returned null for $modelDir');
    }
    _modelAddress = address;
  }

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) {
    final address = _modelAddress;
    if (address == null) {
      throw const NeedleEngineException('Model is not loaded.');
    }
    return Isolate.run(
      () => _completeSync(address, messagesJson, toolsJson, optionsJson),
    );
  }

  @override
  Future<void> unload() async {
    final address = _modelAddress;
    _modelAddress = null;
    if (address != null) {
      await Isolate.run(() => _destroySync(address));
    }
  }
}

const _responseBufferBytes = 64 * 1024;

int _initSync(String modelDir) {
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
      throw NeedleEngineException('cactus_complete failed: status $written');
    }
    return buffer.cast<Utf8>().toDartString();
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
