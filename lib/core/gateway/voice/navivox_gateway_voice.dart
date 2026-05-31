import '../../protocol/navivox_json.dart';

class NavivoxProfileVoiceProfile {
  const NavivoxProfileVoiceProfile({
    this.sttProvider = '',
    this.ttsProvider = '',
    this.voiceId = '',
    this.languagePolicy = '',
    this.fallbackVoice = '',
  });

  factory NavivoxProfileVoiceProfile.fromJson(Map<String, Object?> json) {
    return NavivoxProfileVoiceProfile(
      sttProvider: navivoxStringFromJson(json['stt_provider'], fallback: ''),
      ttsProvider: navivoxStringFromJson(json['tts_provider'], fallback: ''),
      voiceId: navivoxStringFromJson(json['voice_id'], fallback: ''),
      languagePolicy: navivoxStringFromJson(
        json['language_policy'],
        fallback: '',
      ),
      fallbackVoice: navivoxStringFromJson(
        json['fallback_voice'],
        fallback: '',
      ),
    );
  }

  final String sttProvider;
  final String ttsProvider;
  final String voiceId;
  final String languagePolicy;
  final String fallbackVoice;

  Map<String, Object?> toJson() {
    return {
      if (sttProvider.trim().isNotEmpty) 'stt_provider': sttProvider.trim(),
      if (ttsProvider.trim().isNotEmpty) 'tts_provider': ttsProvider.trim(),
      if (voiceId.trim().isNotEmpty) 'voice_id': voiceId.trim(),
      if (languagePolicy.trim().isNotEmpty)
        'language_policy': languagePolicy.trim(),
      if (fallbackVoice.trim().isNotEmpty)
        'fallback_voice': fallbackVoice.trim(),
    };
  }
}

class NavivoxVoiceProviderMatrix {
  const NavivoxVoiceProviderMatrix({
    this.sttProviders = const [],
    this.ttsProviders = const [],
  });

  factory NavivoxVoiceProviderMatrix.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProviderMatrix(
      sttProviders: navivoxStringListFromJson(json['stt']),
      ttsProviders: navivoxStringListFromJson(json['tts']),
    );
  }

  final List<String> sttProviders;
  final List<String> ttsProviders;
}

class NavivoxVoiceCredentialStatus {
  const NavivoxVoiceCredentialStatus({
    required this.configured,
    required this.required,
    required this.status,
    this.source = '',
  });

  factory NavivoxVoiceCredentialStatus.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceCredentialStatus(
      configured: json['configured'] == true,
      required: json['required'] == true,
      status: navivoxStringFromJson(json['status'], fallback: ''),
      source: navivoxStringFromJson(json['source'], fallback: ''),
    );
  }

  final bool configured;
  final bool required;
  final String status;
  final String source;
}

class NavivoxVoiceProfileFieldError {
  const NavivoxVoiceProfileFieldError({
    required this.field,
    required this.code,
    required this.message,
  });

  factory NavivoxVoiceProfileFieldError.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProfileFieldError(
      field: navivoxStringFromJson(json['field'], fallback: ''),
      code: navivoxStringFromJson(json['code'], fallback: ''),
      message: navivoxStringFromJson(json['message'], fallback: ''),
    );
  }

  final String field;
  final String code;
  final String message;
}

class NavivoxVoiceProfileValidation {
  const NavivoxVoiceProfileValidation({
    required this.profileId,
    required this.voiceProfile,
    required this.valid,
    this.errors = const [],
    this.credentialStatusRefs = const {},
  });

  factory NavivoxVoiceProfileValidation.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProfileValidation(
      profileId: navivoxStringFromJson(json['profile_id'], fallback: ''),
      voiceProfile: NavivoxProfileVoiceProfile.fromJson(
        navivoxMapFromJson(json['voice_profile']),
      ),
      valid: json['valid'] == true,
      errors: _voiceProfileErrorsFromJson(json['errors']),
      credentialStatusRefs: _voiceCredentialRefsFromJson(
        json['credential_status_refs'],
      ),
    );
  }

  final String profileId;
  final NavivoxProfileVoiceProfile voiceProfile;
  final bool valid;
  final List<NavivoxVoiceProfileFieldError> errors;
  final Map<String, NavivoxVoiceCredentialStatus> credentialStatusRefs;
}

class NavivoxVoiceProfileView {
  const NavivoxVoiceProfileView({
    required this.profileId,
    required this.displayName,
    required this.voiceProfile,
    this.credentialStatusRefs = const {},
    required this.valid,
    this.errors = const [],
  });

  factory NavivoxVoiceProfileView.fromJson(Map<String, Object?> json) {
    final profileId = navivoxStringFromJson(json['profile_id'], fallback: '');
    return NavivoxVoiceProfileView(
      profileId: profileId,
      displayName: navivoxStringFromJson(
        json['display_name'],
        fallback: profileId,
      ),
      voiceProfile: NavivoxProfileVoiceProfile.fromJson(
        navivoxMapFromJson(json['voice_profile']),
      ),
      credentialStatusRefs: _voiceCredentialRefsFromJson(
        json['credential_status_refs'],
      ),
      valid: json['valid'] == true,
      errors: _voiceProfileErrorsFromJson(json['errors']),
    );
  }

  final String profileId;
  final String displayName;
  final NavivoxProfileVoiceProfile voiceProfile;
  final Map<String, NavivoxVoiceCredentialStatus> credentialStatusRefs;
  final bool valid;
  final List<NavivoxVoiceProfileFieldError> errors;
}

class NavivoxVoiceProfilesResponse {
  const NavivoxVoiceProfilesResponse({
    required this.action,
    required this.providerMatrix,
    this.profiles = const [],
  });

  factory NavivoxVoiceProfilesResponse.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProfilesResponse(
      action: navivoxStringFromJson(json['action'], fallback: ''),
      providerMatrix: NavivoxVoiceProviderMatrix.fromJson(
        navivoxMapFromJson(json['provider_matrix']),
      ),
      profiles: navivoxMapListFromJson(
        json['profiles'],
      ).map(NavivoxVoiceProfileView.fromJson).toList(growable: false),
    );
  }

  final String action;
  final NavivoxVoiceProviderMatrix providerMatrix;
  final List<NavivoxVoiceProfileView> profiles;
}

class NavivoxVoiceProfileValidationResponse {
  const NavivoxVoiceProfileValidationResponse({
    required this.action,
    required this.providerMatrix,
    this.validation,
    required this.valid,
    this.errors = const [],
  });

  factory NavivoxVoiceProfileValidationResponse.fromJson(
    Map<String, Object?> json,
  ) {
    final validationJson = navivoxMapFromJson(json['validation']);
    final validation = validationJson.isEmpty
        ? null
        : NavivoxVoiceProfileValidation.fromJson(validationJson);
    final topErrors = _voiceProfileErrorsFromJson(json['errors']);
    return NavivoxVoiceProfileValidationResponse(
      action: navivoxStringFromJson(json['action'], fallback: ''),
      providerMatrix: NavivoxVoiceProviderMatrix.fromJson(
        navivoxMapFromJson(json['provider_matrix']),
      ),
      validation: validation,
      valid: json['valid'] == true || validation?.valid == true,
      errors: topErrors.isNotEmpty ? topErrors : validation?.errors ?? const [],
    );
  }

  final String action;
  final NavivoxVoiceProviderMatrix providerMatrix;
  final NavivoxVoiceProfileValidation? validation;
  final bool valid;
  final List<NavivoxVoiceProfileFieldError> errors;
}

Map<String, NavivoxVoiceCredentialStatus> _voiceCredentialRefsFromJson(
  Object? value,
) {
  if (value is! Map) return const {};
  final refs = <String, NavivoxVoiceCredentialStatus>{};
  for (final entry in value.entries) {
    if (entry.value is Map) {
      refs[entry.key.toString()] = NavivoxVoiceCredentialStatus.fromJson(
        Map<String, Object?>.from(entry.value as Map),
      );
    }
  }
  return refs;
}

List<NavivoxVoiceProfileFieldError> _voiceProfileErrorsFromJson(Object? value) {
  return navivoxMapListFromJson(
    value,
  ).map(NavivoxVoiceProfileFieldError.fromJson).toList(growable: false);
}
