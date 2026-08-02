part of '../hermes_api_channel.dart';

/// Bounded, redacted text for `state.errorMessage`, which several screens
/// render verbatim.
String _safeHermesError(Object error) =>
    wingRedactedPreview(error.toString(), maxLength: 240);
