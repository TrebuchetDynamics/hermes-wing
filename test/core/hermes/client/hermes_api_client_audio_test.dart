import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';

void main() {
  test('transcribePcm16 sends a WAV data URL to Hermes Agent', () async {
    late Uri requestUri;
    late Map<String, Object?> requestBody;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://localhost:8642'),
      post: (uri, _, body) async {
        requestUri = uri;
        requestBody = jsonDecode(body) as Map<String, Object?>;
        return '{"transcript":"hello Hermes"}';
      },
    );

    expect(
      await client.transcribePcm16(Uint8List.fromList([1, 2]), profile: 'main'),
      'hello Hermes',
    );
    expect(requestUri.path, '/api/audio/transcribe');
    expect(requestUri.queryParameters['profile'], 'main');
    final wav = UriData.parse(
      requestBody['data_url']! as String,
    ).contentAsBytes();
    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
    expect(wav.sublist(44), [1, 2]);
  });

  test('synthesizeSpeech decodes Hermes Agent audio', () async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://localhost:8642'),
      post: (_, _, body) async {
        expect(jsonDecode(body), {'text': 'hello'});
        return '{"data_url":"data:audio/mpeg;base64,AQID"}';
      },
    );

    expect(await client.synthesizeSpeech(' hello '), [1, 2, 3]);
  });
}
