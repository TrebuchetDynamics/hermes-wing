import '../models/hermes_capabilities.dart';
import 'hermes_transport_policy.dart';

enum HermesSurfaceStatus { available, readOnly, deferred, blocked }

extension HermesSurfaceStatusLabel on HermesSurfaceStatus {
  String get label => switch (this) {
    HermesSurfaceStatus.available => 'Available',
    HermesSurfaceStatus.readOnly => 'Read-only',
    HermesSurfaceStatus.deferred => 'Deferred',
    HermesSurfaceStatus.blocked => 'Blocked',
  };
}

class HermesSurfaceReadiness {
  const HermesSurfaceReadiness({
    required this.title,
    required this.status,
    required this.detail,
  });

  final String title;
  final HermesSurfaceStatus status;
  final String detail;
}

List<HermesSurfaceReadiness> hermesSurfaceReadiness(
  HermesCapabilityDocument capabilities,
) {
  final policy = HermesTransportPolicy(capabilities);
  final supportsSessions = capabilities.advertisesEndpoint(
    'sessions',
    'GET',
    '/api/sessions',
  );
  final supportsSessionCreate = capabilities.advertisesEndpoint(
    'session_create',
    'POST',
    '/api/sessions',
  );
  final advertisesJobsList = capabilities.advertisesEndpoint(
    'jobs',
    'GET',
    '/api/jobs',
  );
  final supportsJobsAdmin =
      capabilities.supportsFeature('jobs_admin') && advertisesJobsList;
  final supportsAttachments =
      capabilities.supportsFeature('attachments_api') ||
      capabilities.supportsFeature('multimodal_chat');
  final advertisedServerAudio =
      policy.supportsRealtimeVoice || policy.supportsAudioApi;

  return [
    HermesSurfaceReadiness(
      title: 'Chat transport',
      status: policy.supportsAnyChatTransport
          ? HermesSurfaceStatus.available
          : HermesSurfaceStatus.blocked,
      detail: policy.supportsRunsTransport
          ? 'Runs SSE transport; approval, tool progress, and stop controls are capability-gated separately.'
          : policy.supportsSessionChatStream
          ? 'Session chat streaming fallback.'
          : 'No supported Hermes chat stream endpoint advertised.',
    ),
    HermesSurfaceReadiness(
      title: 'Sessions',
      status: supportsSessions && supportsSessionCreate
          ? HermesSurfaceStatus.available
          : HermesSurfaceStatus.blocked,
      detail: supportsSessions && supportsSessionCreate
          ? 'List, create, select, rename, delete, and fork when advertised.'
          : 'Required session list/create endpoints are missing.',
    ),
    const HermesSurfaceReadiness(
      title: 'Local voice-to-text',
      status: HermesSurfaceStatus.available,
      detail: 'Device speech capture submits transcripts as Hermes text turns.',
    ),
    HermesSurfaceReadiness(
      title: 'Server realtime voice/audio',
      status: advertisedServerAudio
          ? HermesSurfaceStatus.blocked
          : HermesSurfaceStatus.deferred,
      detail: advertisedServerAudio
          ? 'Hermes server audio/realtime voice is advertised, but Navivox has not wired server audio; device STT -> Hermes text remains the voice path.'
          : 'Hermes realtime/server audio is not advertised; device STT -> Hermes text remains the voice path.',
    ),
    HermesSurfaceReadiness(
      title: 'Config editing/admin',
      status: HermesSurfaceStatus.deferred,
      detail: policy.supportsConfigWrite
          ? 'admin_config_rw is advertised, but Hermes config editing is not wired in Navivox.'
          : 'admin_config_rw is not advertised; Navivox keeps this hidden.',
    ),
    HermesSurfaceReadiness(
      title: 'Memory UI',
      status: HermesSurfaceStatus.deferred,
      detail: policy.supportsMemoryWrite
          ? 'Hermes memory API is advertised, but Navivox memory UI is not wired.'
          : 'memory_write_api is not advertised; Hermes memory stays hidden.',
    ),
    HermesSurfaceReadiness(
      title: 'Jobs/schedules inventory',
      status: advertisesJobsList
          ? HermesSurfaceStatus.readOnly
          : HermesSurfaceStatus.deferred,
      detail: advertisesJobsList
          ? 'Jobs list endpoint is advertised; Navivox shows a read-only inventory.'
          : 'Jobs list endpoint is not advertised for mobile use.',
    ),
    HermesSurfaceReadiness(
      title: 'Jobs/schedules admin',
      status: HermesSurfaceStatus.deferred,
      detail: supportsJobsAdmin
          ? 'Jobs admin is advertised, but Navivox has not wired create/edit/delete scheduling; no mobile mutation controls are shown.'
          : 'Jobs create/edit/delete scheduling remains outside the mobile MVP; no mobile mutation controls are shown.',
    ),
    const HermesSurfaceReadiness(
      title: 'Messaging gateways',
      status: HermesSurfaceStatus.deferred,
      detail:
          'No safe mobile Hermes gateway admin contract is wired; no gateway mutation controls are shown.',
    ),
    const HermesSurfaceReadiness(
      title: 'Persona/SOUL',
      status: HermesSurfaceStatus.deferred,
      detail:
          'Persona/SOUL editing is not wired; it needs an explicit Hermes API or safe file/CLI flow before mobile controls appear.',
    ),
    HermesSurfaceReadiness(
      title: 'Attachments/media',
      status: HermesSurfaceStatus.deferred,
      detail: supportsAttachments
          ? 'Attachment/multimodal capability is advertised, but Navivox has not wired mobile attachments; no upload controls are shown.'
          : 'Text-only plus local voice transcript until Hermes exposes a mobile-safe attachment contract and Navivox wires it.',
    ),
    const HermesSurfaceReadiness(
      title: 'Files/context folders',
      status: HermesSurfaceStatus.deferred,
      detail:
          'Files/context folders are not wired; they need mobile-safe workspace and remote path semantics before controls appear.',
    ),
    const HermesSurfaceReadiness(
      title: 'Bounded diagnostics',
      status: HermesSurfaceStatus.readOnly,
      detail:
          'Safe copyable status is available; raw logs and payloads remain excluded.',
    ),
    const HermesSurfaceReadiness(
      title: 'Raw diagnostics/log export',
      status: HermesSurfaceStatus.deferred,
      detail:
          'Raw logs, transcripts, credentials, and tool payload export remain excluded until a safe redaction contract exists.',
    ),
    const HermesSurfaceReadiness(
      title: 'Multi-endpoint/profile management',
      status: HermesSurfaceStatus.available,
      detail:
          'Saved Hermes endpoint profiles can be labeled, selected, renamed, or removed without storing API keys outside secure storage.',
    ),
  ];
}
