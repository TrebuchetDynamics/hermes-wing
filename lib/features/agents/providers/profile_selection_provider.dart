import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel_state.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';

/// The wire id of the Hermes default profile. Selection may seed this before
/// the user picks another profile; it is never posted to a server
/// active-profile endpoint (there is none — selection is client-local).
const String kDefaultProfileId = 'default';

/// Derives the effective client-local selected profile id from [state].
///
/// When the channel has no explicit selection yet, this seeds a default so the
/// UI has profile context on mount: it prefers the advertised default profile
/// ('default'), falling back to the first advertised profile. It returns null
/// only when no profiles are advertised. This is a pure display derivation and
/// never triggers a network call, preserving the invariant that selection
/// never calls an active-profile endpoint.
String? effectiveSelectedProfileId(HermesChannelState state) {
  final selected = state.selectedProfileId;
  if (selected != null && selected.isNotEmpty) return selected;
  if (state.profiles.isEmpty) return null;
  for (final profile in state.profiles) {
    if (profile.id == kDefaultProfileId) return kDefaultProfileId;
  }
  return state.profiles.first.id;
}

/// Global, client-local selected profile id (with default seeding) read from
/// the Hermes channel's current state.
///
/// The channel is a [Listenable], so this provider does not itself rebuild on
/// every state change; widgets that must react to selection rebuild by
/// listening to the channel (e.g. via `AnimatedBuilder`) and read this at build
/// time, or read [effectiveSelectedProfileId] directly.
final profileSelectionProvider = Provider<String?>((ref) {
  final channel = ref.watch(hermesChannelProvider);
  return effectiveSelectedProfileId(channel.state);
});
