part of '../hermes_api_channel.dart';

typedef _HermesOptionalInventory = ({
  List<HermesRuntimeModel> runtimeModels,
  List<String> models,
  List<HermesSkill> skillDetails,
  List<String> skills,
  List<HermesToolset> toolsets,
  List<String> enabledToolsets,
  List<HermesJob> jobs,
});

extension _InventoryExtension on HermesApiChannel {
  // Start every independent read before awaiting; callers own stale-result
  // checks and publish only into the connection/profile that requested them.
  Future<_HermesOptionalInventory> _loadOptionalInventory({
    required HermesApiClient client,
    required HermesCapabilityDocument? capabilities,
    required String? profileId,
    required Map<HermesOptionalResource, String> errors,
  }) async {
    bool canRead(String name, String path) =>
        capabilities != null &&
        _capabilityEndpointAuthorized(capabilities, name, 'GET', path);

    final modelsFuture = _loadOptional<List<HermesRuntimeModel>>(
      advertised: canRead('models', '/v1/models'),
      resource: HermesOptionalResource.models,
      load: () => client.listRuntimeModels(profile: profileId),
      errors: errors,
    );
    final skillsFuture = _loadOptional<List<HermesSkill>>(
      advertised: canRead('skills', '/v1/skills'),
      resource: HermesOptionalResource.skills,
      load: () => client.listSkillDetails(profile: profileId),
      errors: errors,
    );
    final toolsetsFuture = _loadOptional<List<HermesToolset>>(
      advertised: canRead('toolsets', '/v1/toolsets'),
      resource: HermesOptionalResource.toolsets,
      load: () => client.listToolsets(profile: profileId),
      errors: errors,
    );
    final jobsFuture = _loadOptional<List<HermesJob>>(
      // Reuse exact state authorization without requiring settled connection
      // or selection state: both callers are still bootstrapping inventory.
      advertised: HermesChannelState(capabilities: capabilities).canReadJobs,
      resource: HermesOptionalResource.jobs,
      load: () => client.listJobs(profile: profileId),
      errors: errors,
    );
    final runtimeModels = await modelsFuture ?? const <HermesRuntimeModel>[];
    final skillDetails = await skillsFuture ?? const <HermesSkill>[];
    final toolsets = await toolsetsFuture ?? const <HermesToolset>[];
    final jobs = await jobsFuture ?? const <HermesJob>[];
    return (
      runtimeModels: runtimeModels,
      models: runtimeModels.map((model) => model.id).toList(growable: false),
      skillDetails: skillDetails,
      skills: skillDetails.map((skill) => skill.name).toList(growable: false),
      toolsets: toolsets,
      enabledToolsets: toolsets
          .where((toolset) => toolset.enabled)
          .map((toolset) => toolset.name)
          .toList(growable: false),
      jobs: jobs,
    );
  }
}
