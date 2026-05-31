import '../../protocol/navivox_json.dart';

class SavedConnectionFields {
  const SavedConnectionFields({
    required this.baseUrl,
    this.webSocketUrl,
    this.gatewayId,
  });

  factory SavedConnectionFields.fromInput({
    required String baseUrl,
    String? webSocketUrl,
    String? gatewayId,
  }) {
    return SavedConnectionFields(
      baseUrl: baseUrl.trim(),
      webSocketUrl: navivoxOptionalStringFromJson(webSocketUrl),
      gatewayId: navivoxOptionalStringFromJson(gatewayId),
    );
  }

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
}
