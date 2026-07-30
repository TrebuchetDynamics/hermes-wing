// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hermes Wing';

  @override
  String get hermesDestination => 'Hermes';

  @override
  String get agentsDestination => 'Agents';

  @override
  String get officeDestination => 'Office';

  @override
  String get settingsDestination => 'Settings';

  @override
  String get moreDestinations => 'More';

  @override
  String get openMoreDestinations => 'Open more destinations';

  @override
  String get agentsTitle => 'Agents';

  @override
  String get agentsSubtitle => 'Choose how Hermes works for each role.';

  @override
  String get newAgent => 'New Agent';

  @override
  String get agentsLoading => 'Loading agents';

  @override
  String get agentsEmptyTitle => 'No agents available';

  @override
  String get agentsEmptyBody =>
      'Connect with profile access to view Hermes agents.';

  @override
  String get agentsUnavailableTitle => 'Agents unavailable';

  @override
  String get agentsUnavailableBody =>
      'Update Hermes Agent and reconnect this gateway with profile permissions.';

  @override
  String get agentsConnectionError => 'Agents could not be loaded from Hermes.';

  @override
  String get selectedAgent => 'Selected';

  @override
  String get defaultAgent => 'Default';

  @override
  String get readOnlyAccess => 'Read-only access';

  @override
  String agentStableId(String id) {
    return 'ID: $id';
  }

  @override
  String agentSkillsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skills',
      one: '1 skill',
      zero: 'No skills',
    );
    return '$_temp0';
  }

  @override
  String get agentGatewayRunning => 'Gateway running';

  @override
  String get agentGatewayOff => 'Gateway off';

  @override
  String get agentNoModel => 'No model selected';

  @override
  String get chatWithAgent => 'Chat';

  @override
  String get switchingAgent => 'Switching…';

  @override
  String get editAgent => 'Edit';

  @override
  String get createAgentTitle => 'Create agent';

  @override
  String get agentDisplayName => 'Agent name';

  @override
  String get agentNameRequired => 'Enter an agent name.';

  @override
  String get cloneFromAgent => 'Clone from';

  @override
  String get startFresh => 'Start fresh';

  @override
  String get createAction => 'Create';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get retryAction => 'Retry';

  @override
  String get saveAction => 'Save';

  @override
  String get doneAction => 'Done';

  @override
  String get personaLabel => 'Persona';

  @override
  String get personaHint =>
      'Describe this agent’s role, voice, and working style.';

  @override
  String get deleteAgent => 'Delete agent';

  @override
  String deleteAgentTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteAgentBody =>
      'This permanently deletes the agent from Hermes. Type its display name to confirm.';

  @override
  String get deleteConfirmationLabel => 'Agent name';

  @override
  String get defaultAgentCannotDelete => 'The default agent cannot be deleted.';

  @override
  String get profileOperationFailed =>
      'Hermes could not complete that profile change.';

  @override
  String get profileRevisionConflict =>
      'This agent changed elsewhere. The latest version has been loaded; review it before trying again.';

  @override
  String get switchAgent => 'Switch agent';

  @override
  String get switchAgentTitle => 'Switch agent';

  @override
  String switchAgentFailed(String message) {
    return 'Could not switch agent: $message';
  }

  @override
  String get providersDestination => 'Providers';

  @override
  String get toolsDestination => 'Tools';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsSubtitle =>
      'Installed skills and resolved toolsets advertised by this gateway.';

  @override
  String get toolsConnectionRequiredBody =>
      'Open a saved gateway chat before viewing its tool inventory.';

  @override
  String get toolsConnectionErrorBody =>
      'Tool inventory could not be loaded from Hermes.';

  @override
  String get gatewayLabel => 'Gateway';

  @override
  String get selectGatewayHint => 'Select gateway';

  @override
  String get toolsGatewayHelp =>
      'View tool inventory from the selected gateway.';

  @override
  String get gatewayConnectFailed => 'Could not connect to this gateway.';

  @override
  String get officeTitle => 'Office';

  @override
  String get officeSubtitle =>
      'An accessible 2D workspace for agents advertised by your saved Hermes gateways.';

  @override
  String officeAgentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get officeSearchLabel => 'Search agents and gateways';

  @override
  String get officeClearSearch => 'Clear search';

  @override
  String officeShowingCount(int visible, int total) {
    return 'Showing $visible of $total agents';
  }

  @override
  String get officeNoAgentsTitle => 'No Hermes agents available';

  @override
  String get officeNoAgentsBody =>
      'Connect or refresh a saved gateway to populate the Office.';

  @override
  String get officeOpenSettings => 'Open settings';

  @override
  String get officeNoMatches => 'No agents match this search.';

  @override
  String get officeRefresh => 'Refresh Office';

  @override
  String get officeOpenChat => 'Open chat';

  @override
  String get officeCurrentChat => 'Current chat';

  @override
  String get officeReturnToChat => 'Return to chat';

  @override
  String get officeOpenFailed =>
      'Could not open this Hermes agent. Refresh and try again.';

  @override
  String get officeGatewayDefault => 'Gateway default contact';

  @override
  String officeSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get officeStatusOnline => 'Online';

  @override
  String get officeStatusOffline => 'Offline';

  @override
  String get officeStatusRefreshing => 'Refreshing';

  @override
  String get officeStatusAuthenticationFailed => 'Authentication required';

  @override
  String get installedSkillsTitle => 'Installed skills';

  @override
  String get enabledToolsetsTitle => 'Enabled toolsets';

  @override
  String get toolsetsTitle => 'Toolsets';

  @override
  String get searchToolsetsLabel => 'Search toolsets and resolved tools';

  @override
  String get noToolsetsMatchBody => 'No toolsets match this search.';

  @override
  String get toolsetsCatalogEmptyBody => 'No toolsets were reported.';

  @override
  String get toolsetEnabled => 'Enabled';

  @override
  String get toolsetDisabled => 'Disabled';

  @override
  String get toolsetConfigured => 'Configured';

  @override
  String get toolsetNotConfigured => 'Not configured';

  @override
  String toolsetResolvedToolsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resolved tools',
      one: '1 resolved tool',
    );
    return '$_temp0';
  }

  @override
  String get toolsetResolvedToolsTitle => 'Resolved tools';

  @override
  String get skillsUnavailableBody =>
      'This gateway did not advertise installed skill inventory.';

  @override
  String get toolsetsUnavailableBody =>
      'This gateway did not advertise enabled toolset inventory.';

  @override
  String get skillsEmptyBody => 'No installed skills were reported.';

  @override
  String get searchInstalledSkillsLabel => 'Search installed skills';

  @override
  String get noSkillsMatchBody => 'No installed skills match this search.';

  @override
  String get skillsLoadFailedBody =>
      'Installed skills could not be loaded from Hermes.';

  @override
  String get toolsetsLoadFailedBody =>
      'Enabled toolsets could not be loaded from Hermes.';

  @override
  String get schedulesDestination => 'Schedules';

  @override
  String get schedulesTitle => 'Schedules';

  @override
  String get schedulesSubtitle =>
      'Scheduled jobs advertised by the selected gateway and agent.';

  @override
  String get schedulesGatewayHelp =>
      'View schedules from the selected gateway.';

  @override
  String get schedulesConnectionRequiredBody =>
      'Open a saved gateway chat before viewing its schedules.';

  @override
  String get schedulesConnectionErrorBody =>
      'Schedules could not be loaded from Hermes.';

  @override
  String get schedulesUnavailableBody =>
      'This gateway did not advertise scheduled-job inventory.';

  @override
  String get schedulesLoadFailedBody =>
      'Schedules could not be loaded from Hermes.';

  @override
  String get schedulesEmptyBody =>
      'No scheduled jobs were reported for this agent.';

  @override
  String get schedulesReadOnlyNote =>
      'Read-only schedule inventory. Create, pause, trigger, and delete remain hidden until this gateway advertises exact scoped administration contracts.';

  @override
  String get schedulesRefreshTooltip => 'Refresh schedules';

  @override
  String get scheduleEnabled => 'Enabled';

  @override
  String get scheduleDisabled => 'Disabled';

  @override
  String get scheduleActive => 'Active';

  @override
  String get schedulePaused => 'Paused';

  @override
  String get scheduleCompleted => 'Completed';

  @override
  String get scheduleExpressionLabel => 'Schedule';

  @override
  String get scheduleNextRunLabel => 'Next run';

  @override
  String get scheduleLastRunLabel => 'Last run';

  @override
  String get scheduleLastErrorNotice => 'Last run reported an error.';

  @override
  String get gatewayDestination => 'Gateway';

  @override
  String get gatewayStatusTitle => 'Gateway';

  @override
  String get gatewayStatusSubtitle =>
      'Bounded health status advertised by the selected Hermes gateway.';

  @override
  String get gatewayStatusHelp => 'View status from the selected gateway.';

  @override
  String get gatewayStatusConnectionRequiredBody =>
      'Open a saved gateway chat before viewing gateway status.';

  @override
  String get gatewayStatusConnectionErrorBody =>
      'Gateway status could not be loaded from Hermes.';

  @override
  String get gatewayStatusUnavailableBody =>
      'This gateway did not advertise detailed health status.';

  @override
  String get gatewayStatusLoadFailedBody =>
      'Detailed gateway status could not be loaded from Hermes.';

  @override
  String get gatewayStatusReadOnlyNote =>
      'Read-only gateway status. Lifecycle, logs, and messaging-platform administration remain hidden until exact scoped contracts are advertised.';

  @override
  String get gatewayStatusRefreshTooltip => 'Refresh gateway status';

  @override
  String get gatewayHealthy => 'Healthy';

  @override
  String get gatewayNeedsAttention => 'Needs attention';

  @override
  String get gatewayPlatformLabel => 'Platform';

  @override
  String get gatewayVersionLabel => 'Version';

  @override
  String get gatewayRuntimeStateLabel => 'Runtime state';

  @override
  String get gatewayActiveAgentsLabel => 'Active agents';

  @override
  String get gatewayWorkStateLabel => 'Work state';

  @override
  String get gatewayBusy => 'Busy';

  @override
  String get gatewayIdle => 'Idle';

  @override
  String get gatewayDrainableLabel => 'Safe to drain';

  @override
  String get gatewayYes => 'Yes';

  @override
  String get gatewayNo => 'No';

  @override
  String get gatewayUpdatedLabel => 'Updated';

  @override
  String get gatewayProcessIdLabel => 'Process ID';

  @override
  String get gatewayExitReasonLabel => 'Exit reason';

  @override
  String get gatewayRuntimeReadinessTitle => 'Runtime readiness';

  @override
  String get gatewayMessagingPlatformsTitle => 'Messaging platforms';

  @override
  String get gatewayStateDatabaseLabel => 'State database';

  @override
  String get gatewayConfigurationLabel => 'Configuration';

  @override
  String get gatewayModelReadinessLabel => 'Model';

  @override
  String get gatewayDiskReadinessLabel => 'Disk';

  @override
  String get gatewayRuntimeReadinessLabel => 'Gateway runtime';

  @override
  String get gatewayBackgroundQueuesLabel => 'Background queues';

  @override
  String gatewayReadinessDiskUsage(String usedPercent) {
    return '$usedPercent% used';
  }

  @override
  String gatewayReadinessPlatformCounts(int connected, int configured) {
    return '$connected of $configured connected';
  }

  @override
  String gatewayReadinessQueueCounts(
    int activeRuns,
    int completions,
    int delegations,
  ) {
    return '$activeRuns API runs · $completions completions · $delegations delegations';
  }

  @override
  String get providersTitle => 'Providers';

  @override
  String get providersSubtitle =>
      'Set provider credentials and choose models for this agent.';

  @override
  String get providersGatewayHelp =>
      'Manage providers and models on the selected gateway.';

  @override
  String get providersLoading => 'Loading providers';

  @override
  String get providersConnectionError =>
      'Providers could not be loaded from Hermes.';

  @override
  String get providersUnavailableTitle => 'Providers unavailable';

  @override
  String get providersUnavailableBody =>
      'Hermes did not advertise provider access for this connection.';

  @override
  String get providersEmptyTitle => 'No providers available';

  @override
  String get providersEmptyBody =>
      'Connect with provider access to manage credentials.';

  @override
  String get providerConfiguredBadge => 'Configured';

  @override
  String get providerNotConfiguredBadge => 'Not configured';

  @override
  String providerKeyHintLabel(String hint) {
    return 'Key $hint';
  }

  @override
  String get manageCredentialAction => 'Manage credential';

  @override
  String get providerOperationFailed =>
      'The provider operation could not be completed.';

  @override
  String get modelSelectionTitle => 'Model selection';

  @override
  String get modelSelectionUnavailableBody =>
      'Hermes did not advertise model access for this connection.';

  @override
  String get runtimeModelsTitle => 'Runtime models';

  @override
  String get runtimeModelsBody =>
      'Read-only models advertised by this gateway. Provider credentials and assignments remain unavailable.';

  @override
  String get runtimeModelsEmptyBody => 'No runtime models were reported.';

  @override
  String get runtimeModelPrimary => 'Primary runtime model';

  @override
  String get runtimeModelRouteAlias => 'Route alias';

  @override
  String runtimeModelRoutesTo(String model) {
    return 'Routes to $model';
  }

  @override
  String runtimeModelParent(String model) {
    return 'Parent $model';
  }

  @override
  String get activeModelLabel => 'Active model';

  @override
  String get noModelAssigned => 'No model assigned';

  @override
  String get auxiliaryModelsLabel => 'Auxiliary models';

  @override
  String auxiliaryModelSummary(String task, String provider, String model) {
    return '$task: $provider / $model';
  }

  @override
  String get chooseModelAction => 'Choose model';

  @override
  String get refreshCatalogAction => 'Refresh catalog';

  @override
  String get modelPickerTitle => 'Select model';

  @override
  String get modelSlotLabel => 'Slot';

  @override
  String get modelSlotMain => 'Main';

  @override
  String get modelProviderLabel => 'Provider';

  @override
  String get modelNameLabel => 'Model';

  @override
  String get assignModelAction => 'Assign';

  @override
  String get modelCatalogEmpty =>
      'No models in the catalog. Refresh to fetch the latest.';

  @override
  String get modelAssignmentFailed =>
      'The model assignment could not be saved.';

  @override
  String get modelRevisionConflict =>
      'The model selection changed elsewhere. Reopen the picker to try again.';

  @override
  String credentialSheetTitle(String provider) {
    return '$provider credential';
  }

  @override
  String get credentialWriteOnlyNotice =>
      'Hermes Wing can set this credential but never shows a stored key.';

  @override
  String get credentialEnvVarLabel => 'Environment variable';

  @override
  String get credentialValueLabel => 'New secret value';

  @override
  String get credentialValueRequired => 'Enter a value to set.';

  @override
  String get setCredentialAction => 'Set';

  @override
  String get removeCredentialAction => 'Remove';

  @override
  String get validateCredentialAction => 'Validate';

  @override
  String get credentialConfiguredStatus => 'Configured';

  @override
  String get credentialNotConfiguredStatus => 'Not configured';

  @override
  String get credentialOperationFailed =>
      'The credential operation could not be completed.';

  @override
  String get copyTranscriptAction => 'Copy transcript';

  @override
  String get copyTranscriptDescription =>
      'Choose a portable transcript format.';

  @override
  String get copyAsTextAction => 'Copy as text';

  @override
  String get copyAsMarkdownAction => 'Copy as Markdown';

  @override
  String get transcriptFormatText => 'text';

  @override
  String get transcriptFormatMarkdown => 'Markdown';

  @override
  String transcriptCopiedMessage(String format) {
    return 'Transcript copied as $format';
  }

  @override
  String get transcriptAuthorYou => 'You';

  @override
  String get transcriptAuthorHermes => 'Hermes';

  @override
  String get transcriptAuthorSystem => 'System';

  @override
  String transcriptToolHeading(String name) {
    return 'Tool: $name';
  }

  @override
  String transcriptToolStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get sessionsToday => 'Today';

  @override
  String get sessionsYesterday => 'Yesterday';

  @override
  String get sessionsThisWeek => 'This week';

  @override
  String get sessionsEarlier => 'Earlier';

  @override
  String get sessionUnknownSource => 'Unknown source';

  @override
  String sessionSourceLabel(String source) {
    return 'Source: $source';
  }

  @override
  String sessionModelLabel(String model) {
    return 'Model: $model';
  }

  @override
  String get sessionModelNotReported => 'Not reported';

  @override
  String get sessionStreamingReply => 'Streaming reply';

  @override
  String get sessionReplyFailed => 'Reply failed';

  @override
  String get transcriptImageFallbackLabel => 'Image';

  @override
  String get transcriptImageNotLoaded => 'image not loaded';

  @override
  String get copyCodeAction => 'Copy code';

  @override
  String get codeCopiedMessage => 'Code copied';

  @override
  String get showMoreAction => 'Show more';

  @override
  String get showLessAction => 'Show less';

  @override
  String get reasoningTitle => 'Reasoning';

  @override
  String get localCommandsTitle => 'Wing commands';

  @override
  String get localCommandsHelpTitle => 'Wing commands';

  @override
  String get localCommandsHelpBody =>
      'These commands run on this device and are never sent to Hermes Agent.';

  @override
  String get localCommandHelpDescription => 'Show Wing-owned commands.';

  @override
  String get localCommandToolsDescription =>
      'Open installed skills and toolsets.';

  @override
  String get localCommandSkillsDescription => 'Open installed skills.';

  @override
  String get localCommandGatewayDescription => 'Open gateway status.';

  @override
  String get localCommandOfficeDescription =>
      'Open the accessible agent workspace.';

  @override
  String get localCommandAgentsDescription => 'Open gateway-scoped agents.';

  @override
  String get localCommandProvidersDescription => 'Open providers and models.';

  @override
  String get localCommandModelDescription =>
      'Open provider and model management.';

  @override
  String get localCommandSchedulesDescription => 'Open gateway schedules.';

  @override
  String get localCommandPersonaDescription =>
      'Show the selected agent persona.';

  @override
  String get localCommandVersionDescription =>
      'Show the connected gateway version.';

  @override
  String gatewayVersionSummary(String platform, String version) {
    return 'Gateway version: $platform $version';
  }

  @override
  String get gatewayVersionUnavailable => 'Gateway version is unavailable.';

  @override
  String get gatewayVersionUnknown => 'version unknown';

  @override
  String profilePersonaTitle(String profile) {
    return '$profile persona';
  }

  @override
  String get profilePersonaEmptyBody => 'This agent has no persona content.';

  @override
  String profilePersonaLoadFailed(String error) {
    return 'Persona could not be loaded: $error';
  }

  @override
  String get localCommandNewDescription => 'Start a new Hermes session.';

  @override
  String get localCommandSessionsDescription => 'Open session history.';

  @override
  String desktopSessionsShortcutTooltip(String modifier) {
    return 'Sessions ($modifier+K)';
  }

  @override
  String desktopNewSessionShortcutTooltip(String modifier) {
    return 'New session ($modifier+N)';
  }

  @override
  String get localCommandClearDescription => 'Clear the current draft.';

  @override
  String get localCommandSettingsDescription => 'Open Wing settings.';

  @override
  String get localCommandUsageDescription =>
      'Show token usage for the latest reply.';

  @override
  String get noRunTokenUsageMessage =>
      'No server-reported token usage is available yet.';

  @override
  String runTokenUsage(int inputTokens, int outputTokens, int totalTokens) {
    return '$inputTokens in · $outputTokens out · $totalTokens total tokens';
  }

  @override
  String transcriptRunTokenUsage(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  ) {
    return 'Usage: $inputTokens input · $outputTokens output · $totalTokens total tokens';
  }

  @override
  String runTokenUsageSemantics(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  ) {
    return 'Token usage: $inputTokens input, $outputTokens output, $totalTokens total';
  }

  @override
  String get auxiliaryTaskVision => 'Vision';

  @override
  String get auxiliaryTaskWebExtract => 'Web extract';

  @override
  String get auxiliaryTaskCompression => 'Compression';

  @override
  String get auxiliaryTaskSkillsHub => 'Skills hub';

  @override
  String get auxiliaryTaskApproval => 'Approval';

  @override
  String get auxiliaryTaskMcp => 'MCP';

  @override
  String get auxiliaryTaskTitleGeneration => 'Title generation';

  @override
  String get auxiliaryTaskTriageSpecifier => 'Triage specifier';

  @override
  String get auxiliaryTaskKanbanDecomposer => 'Kanban decomposer';

  @override
  String get auxiliaryTaskProfileDescriber => 'Profile describer';

  @override
  String get auxiliaryTaskCurator => 'Curator';
}
