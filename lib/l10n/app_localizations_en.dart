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
  String get agentsDestination => 'Profiles';

  @override
  String get officeDestination => 'Office';

  @override
  String get settingsDestination => 'Settings';

  @override
  String get moreDestinations => 'More';

  @override
  String get openMoreDestinations => 'Open more destinations';

  @override
  String get agentsTitle => 'Profiles';

  @override
  String get agentsSubtitle => 'Choose how Hermes works for each profile.';

  @override
  String get newAgent => 'New Profile';

  @override
  String get agentsLoading => 'Loading profiles';

  @override
  String get agentsEmptyTitle => 'No profiles available';

  @override
  String get agentsEmptyBody =>
      'Connect with profile access to view Hermes profiles.';

  @override
  String get agentsUnavailableTitle => 'Profiles unavailable';

  @override
  String get agentsUnavailableBody =>
      'Update Hermes Agent and reconnect this gateway with profile permissions.';

  @override
  String get agentsConnectionError =>
      'Profiles could not be loaded from Hermes.';

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
  String get agentGatewayUnknown => 'Gateway state unknown';

  @override
  String get managedByWingLink => 'Managed by Wing Link';

  @override
  String get profileEnrolled => 'Enrolled';

  @override
  String get profileNotEnrolled => 'Not enrolled';

  @override
  String get agentNoModel => 'No model selected';

  @override
  String get agentsLocalLoadError => 'Could not load local profiles.';

  @override
  String get agentsGatewayConnectError => 'Could not connect to this gateway.';

  @override
  String get profileStableNameHint =>
      'Use 1–64 lowercase letters, numbers, _ or -.';

  @override
  String get chatWithAgent => 'Chat';

  @override
  String get profileChatUnavailable =>
      'Management only — this Hermes endpoint does not advertise profile chat context.';

  @override
  String get profileBrowseFoldersAction => 'Browse folders';

  @override
  String get directoryBrowserTitle => 'Approved folders';

  @override
  String get directoryBrowserLoading => 'Loading approved folders';

  @override
  String get directoryBrowserEmptyTitle => 'No approved folders';

  @override
  String get directoryBrowserEmptyBody =>
      'Approve a root on the host with: wing-link directories grant PATH';

  @override
  String get directoryBrowserError =>
      'Approved folders are unavailable. Refresh the host grants and try again.';

  @override
  String get directoryBrowserUnavailable =>
      'Folder browsing is unavailable for this Wing Link device. Update Wing Link or pair again with directory access.';

  @override
  String get directoryBrowserBackAction => 'Back';

  @override
  String get directoryBrowserLoadMoreAction => 'Load more';

  @override
  String get directoryBrowserProjectUnavailable =>
      'Folder browsing is available, but Project creation remains unavailable until Hermes Agent advertises a compatible Project API.';

  @override
  String chatWithNamedAgent(String name) {
    return 'Chat with $name';
  }

  @override
  String get switchingAgent => 'Switching…';

  @override
  String get editAgent => 'Edit';

  @override
  String editNamedAgent(String name) {
    return 'Edit $name';
  }

  @override
  String get createAgentTitle => 'Create profile';

  @override
  String get agentDisplayName => 'Profile name';

  @override
  String get agentNameRequired => 'Enter a profile name.';

  @override
  String get profileDescriptionLabel => 'Description';

  @override
  String get profileProviderLabel => 'Provider';

  @override
  String get profileProviderRequired => 'Enter a provider.';

  @override
  String get profileModelLabel => 'Model';

  @override
  String get profileModelRequired => 'Enter a model.';

  @override
  String get profileCredentialLabel => 'New provider credential';

  @override
  String get profileCredentialHint =>
      'Optional. This value is write-only and is never shown again.';

  @override
  String get profileReadinessNotice =>
      'Saving sends one ‘Hi’ through Hermes to verify that this provider and model can answer.';

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
      'Describe this profile’s role, voice, and working style.';

  @override
  String get deleteAgent => 'Delete profile';

  @override
  String deleteNamedAgent(String name) {
    return 'Delete $name';
  }

  @override
  String deleteAgentTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteAgentBody =>
      'This permanently deletes the profile from Hermes. Type its display name to confirm.';

  @override
  String get deleteConfirmationLabel => 'Profile name';

  @override
  String get defaultAgentCannotDelete =>
      'The default profile cannot be deleted.';

  @override
  String get profileOperationFailed =>
      'Hermes could not complete that profile change.';

  @override
  String get profileRevisionConflict =>
      'This profile changed elsewhere. The latest version has been loaded; review it before trying again.';

  @override
  String get switchAgent => 'Switch profile';

  @override
  String get switchAgentTitle => 'Switch profile';

  @override
  String switchAgentFailed(String message) {
    return 'Could not switch profile: $message';
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
  String get shellProfileLabel => 'Profile';

  @override
  String get shellModelLabel => 'Model';

  @override
  String get shellInventoryLabel => 'Inventory';

  @override
  String shellConnectedHost(String host) {
    return 'Connected · $host';
  }

  @override
  String get shellDisconnected => 'Disconnected';

  @override
  String get shellNotLoaded => 'Not loaded';

  @override
  String get shellUnavailable => 'Unavailable';

  @override
  String shellInventorySummary(int tools, int skills) {
    String _temp0 = intl.Intl.pluralLogic(
      tools,
      locale: localeName,
      other: '$tools tools',
      one: '1 tool',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skills,
      locale: localeName,
      other: '$skills skills',
      one: '1 skill',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get selectGatewayHint => 'Select gateway';

  @override
  String get gatewaySelectPromptTitle => 'Select a gateway';

  @override
  String get toolsUnavailableTitle => 'Tools unavailable';

  @override
  String get schedulesUnavailableTitle => 'Schedules unavailable';

  @override
  String get gatewayStatusUnavailableTitle => 'Gateway status unavailable';

  @override
  String get agentsConnectionRequiredBody =>
      'Open a saved gateway chat before managing its profiles.';

  @override
  String get providersConnectionRequiredBody =>
      'Open a saved gateway chat before managing providers and models.';

  @override
  String get toolsGatewayHelp =>
      'View tool inventory from the selected gateway.';

  @override
  String get gatewayConnectFailed => 'Could not connect to this gateway.';

  @override
  String get gatewayDisconnectTitle => 'Disconnect from this gateway?';

  @override
  String get gatewayDisconnectBody =>
      'Hermes Wing will close this connection. The saved gateway and API key stay on this device so you can reconnect later.';

  @override
  String get gatewayDisconnectFailed =>
      'Could not disconnect from this gateway.';

  @override
  String get officeTitle => 'Office';

  @override
  String get officeSubtitle =>
      'An accessible 2D workspace for profiles advertised by your saved Hermes gateways.';

  @override
  String officeAgentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles',
      one: '1 profile',
    );
    return '$_temp0';
  }

  @override
  String get officeSearchLabel => 'Search profiles and gateways';

  @override
  String get officeClearSearch => 'Clear search';

  @override
  String officeShowingCount(int visible, int total) {
    return 'Showing $visible of $total profiles';
  }

  @override
  String get officeNoAgentsTitle => 'No Hermes profiles available';

  @override
  String get officeNoAgentsBody =>
      'Connect or refresh a saved gateway to populate the Office.';

  @override
  String get officeOpenSettings => 'Open settings';

  @override
  String get officeNoMatches => 'No profiles match this search.';

  @override
  String get officeRefresh => 'Refresh Office';

  @override
  String get officeOpenChat => 'Open chat';

  @override
  String get officeProfileManagementOnly => 'Management only';

  @override
  String get officeCurrentChat => 'Current chat';

  @override
  String get officeReturnToChat => 'Return to chat';

  @override
  String get officeOpenFailed =>
      'Could not open this Hermes profile. Refresh and try again.';

  @override
  String get officeGatewayDefault => 'Gateway endpoint contact';

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
      'Scheduled jobs advertised by the selected gateway and profile.';

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
      'No scheduled jobs were reported for this profile.';

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
  String get scheduleError => 'Error';

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
  String get gatewayTrustTitle => 'Wing Link trust';

  @override
  String get gatewayTrustLoading =>
      'Checking pinned host identity and device grants…';

  @override
  String get gatewayTrustUnavailable =>
      'Wing Link trust status is unavailable. Verify the host is online and the saved identity has not changed.';

  @override
  String get gatewayTrustFingerprint => 'Host fingerprint';

  @override
  String get gatewayTrustProtocol => 'Protocol';

  @override
  String get gatewayTrustDevice => 'This device';

  @override
  String get gatewayTrustScopes => 'Granted scopes';

  @override
  String get gatewayTrustHostInstructions =>
      'Trust changes require the host console: wing-link devices list · wing-link approvals list';

  @override
  String get gatewayTrustRevokeAction => 'Revoke this device';

  @override
  String get gatewayTrustRevokeTitle => 'Revoke this device?';

  @override
  String get gatewayTrustRevokeBody =>
      'This removes only this device\'s Wing Link credential. Reconnecting requires a new host pairing flow.';

  @override
  String get gatewayTrustRevoked =>
      'This device was revoked. Pair it again from the host to restore management access.';

  @override
  String get gatewayTrustChangedIdentity =>
      'The host fingerprint changed. Wing Link access is blocked; review the fingerprint at the host and pair again explicitly.';

  @override
  String get gatewayTrustUpgradeRequired =>
      'This Wing Link protocol is outside the supported compatibility window. Upgrade Hermes Wing before reconnecting.';

  @override
  String get gatewayTrustCredentialExpired =>
      'This device credential is expired or revoked. Create a new pairing flow at the host.';

  @override
  String get gatewayTrustApprovalPending =>
      'Host confirmation is pending. Run wing-link approvals list on the host, review the request, then retry with the same operation.';

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
  String get gatewayStatusBasicOnlyBody =>
      'Connected. Showing basic health because this gateway does not advertise detailed status.';

  @override
  String get gatewayStatusDetailedFallbackBody =>
      'Connected. Basic health is available, but detailed status could not be loaded.';

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
  String get gatewayActiveAgentsLabel => 'Active profiles';

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
      'Set provider credentials and choose models for this profile.';

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
  String get providersConfiguredSection => 'Configured providers';

  @override
  String get providersAvailableSection => 'Available providers';

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
  String get sessionModelPickerTitle => 'Use a model for this session';

  @override
  String get sessionModelPickerDescription =>
      'Hermes Agent will keep this model selection scoped to the current session.';

  @override
  String get sessionModelLockAction => 'Use for session';

  @override
  String get sessionModelLockFailed =>
      'Hermes could not confirm this session model.';

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
  String get chatImageAttachmentTypeLabel => 'IMAGE';

  @override
  String get chatFileAttachmentTypeLabel => 'FILE';

  @override
  String chatImageAttachmentLabel(String name) {
    return 'Image attachment: $name';
  }

  @override
  String chatFileAttachmentLabel(String name) {
    return 'File attachment: $name';
  }

  @override
  String chatFileExtensionTypeLabel(String extension) {
    return '$extension FILE';
  }

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
  String get localCommandsKeyboardHint =>
      '↑↓ navigate  •  Enter select  •  Tab complete';

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
      'Open the accessible profile workspace.';

  @override
  String get localCommandAgentsDescription => 'Open gateway-scoped profiles.';

  @override
  String get localCommandProvidersDescription => 'Open providers and models.';

  @override
  String get localCommandModelDescription =>
      'Open provider and model management.';

  @override
  String get localCommandSchedulesDescription => 'Open gateway schedules.';

  @override
  String get localCommandPersonaDescription =>
      'Show the selected profile persona.';

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
  String get profilePersonaEmptyBody => 'This profile has no persona content.';

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
      'Show server-reported usage for the latest Hermes run.';

  @override
  String get noRunTokenUsageMessage =>
      'No server-reported Hermes run usage is available yet.';

  @override
  String runTokenUsage(int inputTokens, int outputTokens, int totalTokens) {
    return 'Latest Hermes run · $inputTokens input · $outputTokens output · $totalTokens total';
  }

  @override
  String transcriptRunTokenUsage(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  ) {
    return 'Latest Hermes run usage: $inputTokens input · $outputTokens output · $totalTokens total tokens';
  }

  @override
  String runTokenUsageSemantics(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  ) {
    return 'Latest Hermes run token usage: $inputTokens input, $outputTokens output, $totalTokens total. Input can include instructions, conversation context, and tool results; this is not a billing estimate.';
  }

  @override
  String get runTokenUsageTooltip =>
      'Latest server-reported Hermes run. Input may include instructions, conversation context, and tool results. This is not a billing estimate.';

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

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsConnectionSection => 'Connection';

  @override
  String get diagnosticsStatusLabel => 'Status';

  @override
  String get diagnosticsStatusDisconnected => 'Disconnected';

  @override
  String get diagnosticsStatusConnecting => 'Connecting';

  @override
  String get diagnosticsStatusConnected => 'Connected';

  @override
  String get diagnosticsStatusError => 'Error';

  @override
  String get diagnosticsModelLabel => 'Model';

  @override
  String get diagnosticsModelNotReported => 'Not reported';

  @override
  String get diagnosticsRunTransportLabel => 'Run transport';

  @override
  String get diagnosticsTransportNotConnected => 'Not connected';

  @override
  String get diagnosticsTransportRunsSse => 'Runs SSE enabled';

  @override
  String get diagnosticsTransportSessionStream => 'Session chat streaming';

  @override
  String get diagnosticsTransportUnavailable => 'Unavailable';

  @override
  String get diagnosticsVersionHealthLabel => 'Version / health';

  @override
  String get diagnosticsNoHealthDetails => 'No health details yet';

  @override
  String get diagnosticsUnknownVersion => 'unknown version';

  @override
  String get diagnosticsUnknownGateway => 'unknown gateway';

  @override
  String diagnosticsHealthSummary(String version, String gateway) {
    return '$version • $gateway';
  }

  @override
  String get diagnosticsInventorySection => 'Inventory';

  @override
  String get diagnosticsResourcesLabel => 'Resources';

  @override
  String diagnosticsResourcesSummary(
    int models,
    int skills,
    int toolsets,
    int jobs,
  ) {
    return '$models models • $skills skills • $toolsets toolsets • $jobs jobs';
  }

  @override
  String get diagnosticsInventoryWarningsLabel => 'Inventory warnings';

  @override
  String diagnosticsUnavailableSummary(String resources) {
    return '$resources unavailable';
  }

  @override
  String get diagnosticsResourceHealth => 'health';

  @override
  String get diagnosticsResourceModels => 'models';

  @override
  String get diagnosticsResourceSkills => 'skills';

  @override
  String get diagnosticsResourceToolsets => 'toolsets';

  @override
  String get diagnosticsResourceJobs => 'jobs';

  @override
  String get diagnosticsSessionsSection => 'Sessions';

  @override
  String diagnosticsSessionsSummary(int count, String active) {
    return '$count sessions • active $active';
  }

  @override
  String get diagnosticsActiveYes => 'yes';

  @override
  String get diagnosticsActiveNone => 'none';

  @override
  String get diagnosticsExportSection => 'Export';

  @override
  String get diagnosticsCopyTitle => 'Copy diagnostics';

  @override
  String get diagnosticsCopySubtitle =>
      'Safe snapshot; excludes secrets, raw logs, transcripts, and local paths.';

  @override
  String get diagnosticsCopiedNotice => 'Hermes diagnostics copied';

  @override
  String get voiceSettingsTitle => 'Voice & speech';

  @override
  String get voiceBehaviorSection => 'Voice behavior';

  @override
  String get voiceContinuousTitle => 'Continuous voice';

  @override
  String get voiceContinuousSubtitle =>
      'Allow on-device STT transcripts to be sent to Hermes';

  @override
  String get voiceSpeakRepliesTitle => 'Speak replies aloud';

  @override
  String get voiceSpeakRepliesSubtitle =>
      'Allow hands-free voice to speak Hermes replies aloud; the chat\'s hands-free switch turns this on and off';

  @override
  String get voiceCompletionSoundTitle => 'Response completion sound';

  @override
  String get voiceCompletionSoundSubtitle =>
      'Play a device alert when a Hermes reply finishes';

  @override
  String get voiceAdvancedSection => 'Advanced';

  @override
  String get voiceRecognitionLanguageTitle => 'Recognition language';

  @override
  String get voiceRecognitionLanguageSubtitle =>
      'Automatic lets the device recognizer choose; fixed modes request one language.';

  @override
  String get voiceCommandWordTitle => 'Command word';

  @override
  String get voiceCommandWordHint =>
      'Say this before “stop”, “pause”, “mute”, or “cancel” while the foreground voice loop is listening.';

  @override
  String get voiceRemoveAction => 'Remove';

  @override
  String get settingsGatewaysSection => 'Gateways';

  @override
  String get settingsNoSavedGateways => 'No saved Hermes gateways';

  @override
  String get settingsConnectAnotherGateway => 'Connect another gateway';

  @override
  String get settingsScanPairingQr => 'Scan a Hermes pairing QR code';

  @override
  String get settingsCredentialsNote =>
      'Credentials stay in secure storage; values hidden';

  @override
  String get settingsVoiceSection => 'Voice';

  @override
  String settingsGatewayActionsTooltip(String label) {
    return 'Gateway actions for $label';
  }

  @override
  String get settingsManageAgentsAction => 'Manage profiles';

  @override
  String get settingsRenameAction => 'Rename';

  @override
  String get settingsUpdateConnectionAction => 'Update connection';

  @override
  String get settingsReconnectAction => 'Reconnect';

  @override
  String get settingsConnectGatewayError =>
      'Could not connect to this gateway.';

  @override
  String get settingsReconnectGatewayError => 'Could not reconnect gateway.';

  @override
  String get settingsRenameGatewayError => 'Could not rename gateway.';

  @override
  String get settingsUpdateConnectionError =>
      'Could not update gateway connection.';

  @override
  String get settingsRemoveGatewayError => 'Could not remove gateway.';

  @override
  String get settingsRenameGatewayTitle => 'Rename gateway';

  @override
  String get settingsGatewayNameLabel => 'Gateway name';

  @override
  String get settingsUpdateConnectionTitle => 'Update gateway connection';

  @override
  String get settingsGatewayUrlLabel => 'Hermes gateway URL';

  @override
  String get settingsGatewayUrlHelper =>
      'HTTPS or trusted private-network origin';

  @override
  String get settingsNewTokenLabel => 'New access token (optional)';

  @override
  String get settingsNewTokenHelper =>
      'Leave blank to keep the saved token. Its current value is never shown.';

  @override
  String get settingsClearTokenTitle => 'Remove saved access token';

  @override
  String get settingsClearTokenSubtitle =>
      'Use only when this gateway no longer requires it.';

  @override
  String get settingsActiveGatewayNote =>
      'Return to All chats before changing the active gateway connection.';

  @override
  String get settingsSaveAndReconnect => 'Save and reconnect';

  @override
  String get settingsGatewayOriginError =>
      'Enter an HTTP or HTTPS gateway origin.';

  @override
  String get settingsRemoveGatewayTitle => 'Remove gateway?';

  @override
  String settingsRemoveGatewayBody(String label) {
    return 'Remove $label and its saved credential from this device?';
  }

  @override
  String get enrollTitle => 'Connect to Hermes';

  @override
  String get enrollInvalidLinkTitle => 'Pairing link couldn’t be opened';

  @override
  String get enrollInvalidLinkBody =>
      'Paste another pairing link or scan a new QR code.';

  @override
  String get enrollClipboardEmpty =>
      'The clipboard does not contain a pairing link.';

  @override
  String get enrollCleartextDialogTitle => 'Pair over plain HTTP?';

  @override
  String enrollCleartextDialogBody(String host) {
    return 'The endpoint $host uses plain HTTP. Continue only on a trusted VPN, Tailscale network, or isolated LAN. Prefer HTTPS for remote Hermes endpoints.';
  }

  @override
  String get enrollContinueAction => 'Continue';

  @override
  String get enrollScanPrompt => 'Choose how to connect this device.';

  @override
  String get enrollVerifying => 'Verifying pairing code…';

  @override
  String enrollConnectedProfiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles connected',
      one: '1 profile connected',
    );
    return '$_temp0';
  }

  @override
  String get enrollConnectedBody =>
      'Wing Link is ready for profile and gateway management.';

  @override
  String get enrollViewProfilesAction => 'View profiles';

  @override
  String get enrollOpenChatAction => 'Open chat';

  @override
  String get enrollFailed => 'Pairing failed.';

  @override
  String get enrollInspectionFailedTitle => 'Pairing host couldn’t be reached';

  @override
  String get enrollInspectionFailedBody =>
      'Check that the host is online and this device is on the right network, then paste or scan a new pairing link.';

  @override
  String get enrollExchangeFailedTitle => 'Pairing couldn’t be completed';

  @override
  String get enrollExchangeFailedBody =>
      'Wing did not report a completed connection. Any pending credentials remain available for safe recovery; paste or scan a new pairing link to try again.';

  @override
  String get enrollCloseAction => 'Close';

  @override
  String get enrollExpiredTitle => 'This pairing link expired';

  @override
  String get enrollExpiredBody =>
      'Run wing-link pair again, then open the new link or scan its QR.';

  @override
  String get enrollPasteAnotherLink => 'Paste another link';

  @override
  String get enrollScanAnotherQr => 'Scan another QR';

  @override
  String get enrollPasteLink => 'Paste pairing link';

  @override
  String get enrollSameDeviceHelper =>
      'If the link is on this phone, tap it or share it to Hermes Wing.';

  @override
  String get enrollOpeningScanner => 'Opening scanner…';

  @override
  String get enrollScanQr => 'Scan QR from another screen';

  @override
  String get enrollImportQrImage => 'Choose QR image';

  @override
  String get enrollManualConnectAction => 'Connect one profile manually';

  @override
  String get enrollManualConnectWarning =>
      'This does not import Wing Link or other Hermes profiles.';

  @override
  String enrollGrantQuestion(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connect $count Hermes profiles from $label?',
      one: 'Connect 1 Hermes profile from $label?',
    );
    return '$_temp0';
  }

  @override
  String enrollConnectProfilesAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connect $count profiles',
      one: 'Connect 1 profile',
    );
    return '$_temp0';
  }

  @override
  String get enrollHermesAgentLabel => 'Hermes Agent';

  @override
  String get enrollWingLinkLabel => 'Wing Link';

  @override
  String get enrollProfilesLabel => 'Profiles';

  @override
  String get enrollEndpointLabel => 'Endpoint';

  @override
  String get enrollDeviceLabel => 'Device label';

  @override
  String get enrollUnlabeled => '(unlabeled)';

  @override
  String get enrollRequestedAccess => 'Requested access';

  @override
  String get enrollScopesNone => 'none';

  @override
  String get enrollExpiresLabel => 'Expires';

  @override
  String get enrollExpiryUnknown => 'unknown';

  @override
  String get enrollCleartextNotice =>
      'This endpoint uses plain HTTP. Only continue on a trusted network.';

  @override
  String enrollOriginMismatch(String origin) {
    return 'This pairing server reports a different address ($origin) than the link you opened. Hermes Wing will connect to the link address shown above. Only continue if you trust it.';
  }

  @override
  String get enrollConnectAction => 'Connect';

  @override
  String get closeAction => 'Close';

  @override
  String routeNotFound(String path) {
    return 'Route not found: $path';
  }

  @override
  String get agentsGatewayPickerHelp =>
      'Add and edit profiles on the selected gateway.';

  @override
  String get gatewayContactsEmptyTitle => 'Add your first Hermes profile';

  @override
  String get gatewayContactsEmptyBody =>
      'Connect a gateway to see its profiles and start a conversation.';

  @override
  String get gatewayContactsConnectAction => 'Add gateway or profile';

  @override
  String get chatGroupsNewAction => 'New group';

  @override
  String get chatGroupsNewTitle => 'New group';

  @override
  String get chatGroupsRenameTitle => 'Rename group';

  @override
  String get chatGroupsRenameAction => 'Rename';

  @override
  String get chatGroupsDeleteAction => 'Delete';

  @override
  String get chatGroupsNameLabel => 'Group name';

  @override
  String get chatGroupsUngrouped => 'Ungrouped';

  @override
  String get chatGroupsMoveAction => 'Move to group';

  @override
  String chatQueuedCancelTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cancel $count queued follow-ups?',
      one: 'Cancel $count queued follow-up?',
    );
    return '$_temp0';
  }

  @override
  String chatQueuedMore(int count) {
    return '+$count more';
  }

  @override
  String chatQueuedSummary(int count, String preview) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Queued $count follow-ups after current reply: $preview',
      one: 'Queued $count follow-up after current reply: $preview',
    );
    return '$_temp0';
  }

  @override
  String get chatQueuedWaitingForTransport =>
      'Waiting for a supported Hermes chat transport.';

  @override
  String get chatQueuedWaitingForOriginalSession =>
      'Waiting for the original session.';

  @override
  String get chatQueuedRedactedNote =>
      'Queued text is redacted and bounded in this confirmation.';

  @override
  String chatQueuedAttachmentPreview(String name) {
    return 'Attachment: $name';
  }

  @override
  String get chatQueuedKeepAction => 'Keep';

  @override
  String get chatQueuedCancelAllAction => 'Cancel all';

  @override
  String get chatQueuedManageAction => 'Manage';

  @override
  String get chatQueuedMoreActions => 'More queued follow-up actions';

  @override
  String chatQueuedManageTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queued follow-ups',
      one: '$count queued follow-up',
    );
    return '$_temp0';
  }

  @override
  String get chatQueuedCancelOneAction => 'Cancel queued follow-up';

  @override
  String chatQueuedFullError(int count) {
    return 'Queued follow-ups are full ($count). Wait for Hermes to finish before adding more.';
  }

  @override
  String chatQueuedOpenSessionError(String message) {
    return 'Could not open queued follow-up session: $message';
  }

  @override
  String chatQueuedSendError(String message) {
    return 'Could not send queued follow-up: $message';
  }

  @override
  String chatSteerFailed(String message) {
    return 'Could not guide the active Hermes run: $message';
  }

  @override
  String get chatConnectionRenameProfileTitle => 'Rename Hermes profile';

  @override
  String get chatConnectionProfileLabelLabel => 'Profile label';

  @override
  String get chatConnectionProfileLabelHelper =>
      'Leave blank to show the endpoint URL.';

  @override
  String chatConnectionRenameProfileErrorBody(String error) {
    return 'Could not rename Hermes profile: $error';
  }

  @override
  String get chatConnectionCleartextWarningTitle => 'Send API key without TLS?';

  @override
  String chatConnectionCleartextWarningBody(String endpoint) {
    return 'The endpoint $endpoint uses plain HTTP. Continue only on a trusted VPN, Tailscale network, or isolated LAN. Prefer HTTPS for remote Hermes endpoints.';
  }

  @override
  String get chatConnectionContinueAction => 'Continue';

  @override
  String get chatConnectionDisconnectTitle => 'Disconnect from Hermes?';

  @override
  String chatConnectionDisconnectBody(String target) {
    return 'Disconnect from $target and remove this saved endpoint/API key from this device. Other saved Hermes gateways remain available.';
  }

  @override
  String get chatConnectionDiagnosticsTitle => 'Hermes diagnostics';

  @override
  String get chatConnectionRawLogStatusCopiedBody => 'Raw-log status copied';

  @override
  String get chatConnectionCopyRawLogStatusAction => 'Copy raw-log status';

  @override
  String get chatConnectionDiagnosticsCopiedBody => 'Hermes diagnostics copied';

  @override
  String get chatConnectionCopyAction => 'Copy';

  @override
  String get chatConnectionDisconnectAction => 'Disconnect';

  @override
  String chatSessionActionCreateFailedBody(String error) {
    return 'Could not create session: $error';
  }

  @override
  String chatSessionActionOpenFailedBody(String error) {
    return 'Could not open session: $error';
  }

  @override
  String get chatSessionActionRenameTitle => 'Rename session';

  @override
  String get chatSessionActionTitleFieldLabel => 'Session title';

  @override
  String chatSessionActionRenameFailedBody(String error) {
    return 'Could not rename session: $error';
  }

  @override
  String get chatSessionActionBranchTitle => 'Branch this session?';

  @override
  String chatSessionActionBranchBody(String title) {
    return 'Create a new session with the conversation history from “$title”? The original remains in Hermes and the new branch becomes active.';
  }

  @override
  String get chatSessionActionBranchConfirmAction => 'Create branch';

  @override
  String get chatSessionActionBranchCreatedBody =>
      'Created a new session branch.';

  @override
  String chatSessionActionBranchFailedBody(String error) {
    return 'Could not create session branch: $error';
  }

  @override
  String chatSessionActionDeleteManyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count sessions?',
      one: 'Delete $count session?',
    );
    return '$_temp0';
  }

  @override
  String get chatSessionActionDeleteManyBody =>
      'Delete the selected sessions from Hermes? This cannot be undone.';

  @override
  String get chatSessionActionDeleteAction => 'Delete';

  @override
  String chatSessionActionDeletedCountBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count sessions.',
      one: 'Deleted $count session.',
    );
    return '$_temp0';
  }

  @override
  String chatSessionActionDeletedPartialBody(
    int deleted,
    int count,
    int failed,
  ) {
    return 'Deleted $deleted of $count sessions. $failed could not be deleted.';
  }

  @override
  String get chatSessionActionDeleteTitle => 'Delete session?';

  @override
  String chatSessionActionDeleteBody(String title) {
    return 'Delete \"$title\" from Hermes?';
  }

  @override
  String chatSessionActionDeleteFailedBody(String error) {
    return 'Could not delete session: $error';
  }

  @override
  String get chatTranscriptCopyChatTextAction => 'Copy entire chat (text)';

  @override
  String get chatTranscriptCopyChatMarkdownAction =>
      'Copy entire chat (Markdown)';

  @override
  String get chatTranscriptReplyAction => 'Reply';

  @override
  String get chatTranscriptCopyAction => 'Copy';

  @override
  String get chatTranscriptReadAloudAction => 'Read aloud';

  @override
  String get chatTranscriptReadingAloudLabel => 'Reading aloud';

  @override
  String get chatTranscriptStopReadAloudAction => 'Stop reading aloud';

  @override
  String get chatTranscriptMessageCopiedLabel => 'Message copied';

  @override
  String chatTranscriptFullTimestamp(String date, String time) {
    return '$date, $time';
  }

  @override
  String get chatTranscriptTimestampJustNow => 'Just now';

  @override
  String chatTranscriptTimestampMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String chatTranscriptTimestampHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String chatTranscriptTimestampDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get chatTranscriptToolStatusNeedsAttentionLabel =>
      'Host action needs attention';

  @override
  String get chatTranscriptToolStatusRunningLabel => 'Working on Hermes host';

  @override
  String get chatTranscriptToolStatusCompletedLabel =>
      'Completed on Hermes host';

  @override
  String get chatTranscriptHostActivityTitle => 'Hermes host activity';

  @override
  String get chatTranscriptToolCategoryWeb => 'Web activity';

  @override
  String get chatTranscriptToolCategoryBrowser => 'Browser activity';

  @override
  String get chatTranscriptToolCategoryFiles => 'File activity';

  @override
  String get chatTranscriptToolCategoryCode => 'Code activity';

  @override
  String get chatTranscriptToolCategoryVoice => 'Voice activity';

  @override
  String get chatTranscriptToolCategoryMemory => 'Memory activity';

  @override
  String get chatTranscriptToolCategoryDelegation => 'Delegated activity';

  @override
  String get chatTranscriptToolCategorySchedule => 'Scheduled activity';

  @override
  String chatTranscriptHostActivityCountTitle(int count) {
    return 'Hermes host activity · $count steps';
  }

  @override
  String chatTranscriptHostStepTitle(int step) {
    return 'Host step $step';
  }

  @override
  String chatTranscriptToolActivitySingleTitle(String name) {
    return 'Tool activity: $name';
  }

  @override
  String chatTranscriptToolActivityCountTitle(int count) {
    return 'Tool activity: $count calls';
  }

  @override
  String get chatTranscriptActionBlockedTitle => 'Action blocked';

  @override
  String get chatTranscriptHideDetailsAction => 'Hide details';

  @override
  String get chatTranscriptDetailsAction => 'Details';

  @override
  String get chatErrorAuthRejectedTitle =>
      'Hermes API rejected the saved API key.';

  @override
  String get chatErrorAuthRejectedBody =>
      'Reconnect with a fresh Hermes API key, then retry this message.';

  @override
  String get chatErrorProviderUsageExhaustedTitle =>
      'Provider usage limit reached.';

  @override
  String get chatErrorProviderUsageExhaustedBody =>
      'Choose another provider or model, or wait for the provider\'s usage limit to reset.';

  @override
  String get chatErrorOpenProvidersAction => 'Switch provider or model';

  @override
  String get chatErrorApprovalResponseFailedTitle =>
      'Hermes could not record the approval decision.';

  @override
  String get chatErrorApprovalResponseFailedBody =>
      'Review the request, check that the run is still active, then try the decision again.';

  @override
  String get chatErrorMalformedApprovalTitle =>
      'Hermes sent an incomplete approval request.';

  @override
  String get chatErrorMalformedApprovalBody =>
      'Retry when Hermes can provide an approval id for this run.';

  @override
  String get chatErrorUnsupportedTransportTitle =>
      'Hermes endpoint does not support chat turns.';

  @override
  String get chatErrorUnsupportedTransportBody =>
      'Connect to a Hermes API server that advertises session chat streaming or run events.';

  @override
  String get chatErrorRunStillActiveTitle => 'Hermes run is still active.';

  @override
  String get chatErrorRunStillActiveBody =>
      'Reconnect to reconcile this run before sending it again.';

  @override
  String get chatErrorRunCancelledTitle => 'Hermes run was cancelled.';

  @override
  String get chatErrorRunCancelledBody =>
      'Start a new turn when you are ready.';

  @override
  String get chatErrorRunFailedTitle => 'Hermes run failed.';

  @override
  String get chatErrorRunFailedBody =>
      'Check Hermes, then retry this message when the run is recoverable.';

  @override
  String get chatErrorStreamDroppedTitle => 'Hermes stream dropped.';

  @override
  String get chatErrorStreamDroppedBody =>
      'Check the endpoint/network and send again when Hermes is reachable.';

  @override
  String get chatErrorGenericTitle => 'Hermes could not finish the turn.';

  @override
  String get chatErrorGenericBody => 'Retry when Hermes is ready.';

  @override
  String get chatErrorDetailsAction => 'Details';

  @override
  String get chatErrorUpdateKeyAction => 'Update key';

  @override
  String get chatErrorReconnectAction => 'Reconnect';

  @override
  String get chatErrorRetryLastMessageAction => 'Retry last message';

  @override
  String get chatErrorRedactedDetailsLabel => 'Redacted error details';

  @override
  String get chatErrorRedactionNoteBody =>
      'Secrets, bearer tokens, API keys, cookies, and copied endpoint credentials are redacted before display.';

  @override
  String get chatErrorCopiedRedactedDetailsBody =>
      'Copied redacted Hermes error details.';

  @override
  String get chatErrorCopyRedactedDetailsAction => 'Copy redacted details';

  @override
  String get chatErrorSavedProfilesLabel => 'Saved Hermes profiles';

  @override
  String get chatErrorRenameProfileTooltip => 'Rename Hermes profile';

  @override
  String get chatErrorRemoveProfileTitle => 'Remove saved Hermes profile?';

  @override
  String chatErrorRemoveProfileBody(String label, String baseUrl) {
    return 'Remove $label ($baseUrl) from this device. Any stored API key for this profile is removed from secure storage.';
  }

  @override
  String get chatErrorRemoveProfileAction => 'Remove';

  @override
  String get chatErrorConnectAuthTitle => 'Hermes API rejected the API key.';

  @override
  String get chatErrorConnectAuthBody =>
      'Check the endpoint API key in Hermes and try again.';

  @override
  String get chatErrorConnectUnreachableTitle =>
      'Hermes endpoint is unreachable.';

  @override
  String get chatErrorConnectUnreachableBody =>
      'Check the base URL, network, VPN, and that Hermes API server is running.';

  @override
  String get chatErrorConnectGenericTitle => 'Could not connect to Hermes.';

  @override
  String get chatErrorConnectGenericBody => 'Check the endpoint and try again.';

  @override
  String get chatLayoutConnectTitle => 'Add Hermes';

  @override
  String get chatLayoutConnectBody =>
      'Connect directly to Hermes Agent. Choose how this device can reach it; Wing Link host management stays separate.';

  @override
  String get chatLayoutConnectionModeLabel => 'How will Wing reach Hermes?';

  @override
  String get chatLayoutConnectionModeLocalLabel => 'This device';

  @override
  String get chatLayoutConnectionModeRemoteLabel => 'Remote HTTPS';

  @override
  String get chatLayoutConnectionModeVpnLabel => 'VPN / Tailscale';

  @override
  String get chatLayoutConnectionModeSshLabel => 'SSH tunnel';

  @override
  String get chatLayoutConnectionModeLocalBody =>
      'Use a local Agent URL, or install Hermes on this device when local setup is available.';

  @override
  String get chatLayoutConnectionModeRemoteBody =>
      'Use an HTTPS Agent URL. Wing currently uses HTTPS/SSE; authenticated WebSocket support waits for an exact Hermes contract.';

  @override
  String get chatLayoutConnectionModeVpnBody =>
      'Use the HTTPS Agent URL reachable through your trusted VPN or Tailscale network. Wing does not treat network location as authorization.';

  @override
  String get chatLayoutConnectionModeSshBody =>
      'Start a fixed, trusted SSH tunnel outside Wing, then enter its local Agent URL. Wing never runs arbitrary SSH commands or stores SSH keys.';

  @override
  String get chatLayoutConnectionModeLocalUrlHelper =>
      'Enter the local Agent URL. This device usually uses http://127.0.0.1:8642.';

  @override
  String get chatLayoutConnectionModeRemoteUrlHelper =>
      'Enter the HTTPS Agent URL. Wing currently uses HTTPS/SSE; WebSocket support waits for an exact Hermes contract.';

  @override
  String get chatLayoutConnectionModeVpnUrlHelper =>
      'Enter the HTTPS Agent URL reachable through your trusted VPN or Tailscale network.';

  @override
  String get chatLayoutConnectionModeSshUrlHelper =>
      'Start the fixed tunnel outside Wing, then enter the local Agent URL it exposes.';

  @override
  String get chatLayoutVpsConnectionTitle => 'Hermes Agent connection';

  @override
  String get chatLayoutVpsConnectionBody =>
      'Use an HTTPS or trusted private-network URL. Never expose an unauthenticated Hermes port to the internet.';

  @override
  String get chatLayoutScanQrAction => 'Scan wing-cli QR code';

  @override
  String get chatLayoutServerUrlLabel => 'Hermes Agent URL';

  @override
  String get chatLayoutServerUrlHint => 'https://hermes.example.com';

  @override
  String get chatLayoutServerUrlHelper =>
      'Enter the Agent URL without /v1. For a trusted local or SSH tunnel, a loopback HTTP URL may be used.';

  @override
  String get chatLayoutAccessTokenLabel => 'Access token';

  @override
  String get chatLayoutAccessTokenHelper =>
      'Required for internet-facing servers; optional only on trusted private networks.';

  @override
  String get chatLayoutShowAccessTokenTooltip => 'Show access token';

  @override
  String get chatLayoutHideAccessTokenTooltip => 'Hide access token';

  @override
  String get chatLayoutVpsNameLabel => 'Connection name (optional)';

  @override
  String get chatLayoutVpsNameHint => 'My Hermes connection';

  @override
  String get chatLayoutVpsNameHelper =>
      'A private label shown only on this device.';

  @override
  String get chatLayoutTokenStorageBody =>
      'Your token is stored in secure device storage and is never shown after connecting.';

  @override
  String get chatLayoutCredentialBoundaryTitle => 'Two separate connections';

  @override
  String get chatLayoutCredentialBoundaryBody =>
      'This token is only for Hermes Agent chat. Wing Link pairing, when available, uses a separate management credential and never carries chat traffic.';

  @override
  String get chatLayoutConnectingAction => 'Connecting…';

  @override
  String get chatLayoutConnectAction => 'Add Hermes';

  @override
  String get chatLayoutDevShortcutsTitle => 'Connecting to a local Agent?';

  @override
  String get chatLayoutDevShortcutsBody =>
      'Use a development shortcut instead of a VPS address.';

  @override
  String get chatLayoutPresetThisDeviceLabel => 'This device';

  @override
  String get chatLayoutPresetAndroidEmulatorLabel => 'Android emulator';

  @override
  String get chatLayoutPresetClearAction => 'Clear server details';

  @override
  String get chatLayoutModelFallbackLabel => 'Hermes model';

  @override
  String get chatComposerModelPickerTooltip => 'Choose profile model';

  @override
  String get chatComposerModelsLoadFailed =>
      'Models could not be loaded from Hermes.';

  @override
  String get chatLayoutTransportUnavailableBody =>
      'Hermes did not advertise a supported chat transport for this endpoint.';

  @override
  String get chatLayoutOpenSessionAction => 'Open session';

  @override
  String get chatLayoutFollowUpsCopiedBody =>
      'Copied redacted Hermes queued follow-ups.';

  @override
  String get chatLayoutCopyAction => 'Copy';

  @override
  String get chatLayoutSendNowAction => 'Send now';

  @override
  String get chatLayoutCancelAllAction => 'Cancel all';

  @override
  String get chatLayoutNoSessionsBody =>
      'No Hermes sessions. Create a new session to start chatting.';

  @override
  String get chatLayoutNoSessionsNoCreateBody =>
      'No Hermes sessions are available, and this endpoint did not advertise session creation.';

  @override
  String get chatLayoutVoiceLoopOnLabel => 'Voice loop on';

  @override
  String get chatLayoutVoiceReadyLabel => 'Voice ready';

  @override
  String get chatVoiceCaptureTimedOut => 'Voice capture timed out.';

  @override
  String get chatVoiceMicrophonePermissionDenied =>
      'Microphone permission denied. Grant microphone access in system settings, then return to Hermes Wing.';

  @override
  String get chatVoiceDeviceLanguageUnavailable =>
      'Device speech recognition has no offline language for this device locale. Install that language\'s offline speech data in Android settings, then return to Hermes Wing.';

  @override
  String get chatVoiceDeviceSpeechUnavailable =>
      'Device speech recognition is unavailable. Install or enable device speech recognition, then return to Hermes Wing.';

  @override
  String get chatVoiceNoSpeechDetected =>
      'No speech was recognized. Tap Speak, wait for Listening, then speak clearly and close to the microphone.';

  @override
  String chatVoiceCaptureFailed(String detail) {
    return 'Voice capture failed: $detail';
  }

  @override
  String get chatVoiceCaptureFailedFallback => 'Voice capture failed.';

  @override
  String get chatVoiceCaptureSessionChanged =>
      'Voice capture was discarded because the Hermes session changed.';

  @override
  String get chatVoiceInputUnavailable => 'Voice input is not available here.';

  @override
  String chatVoiceTurnSendFailed(String detail) {
    return 'Voice turn could not be sent: $detail';
  }

  @override
  String get chatVoiceTurnSendFailedFallback => 'Voice turn could not be sent.';

  @override
  String get chatVoiceShutdownTimedOut =>
      'Voice shutdown timed out. Continuous voice paused.';

  @override
  String get chatVoiceShutdownFailed =>
      'Voice shutdown failed. Continuous voice paused.';

  @override
  String get chatVoicePlaybackUnavailable =>
      'Voice playback is unavailable for this connection. The reply is available as text. Voice input remains available from the microphone.';

  @override
  String get chatVoicePlaybackUnavailableContinuous =>
      'Voice playback is unavailable for this connection. The reply is available as text. Hands-free listening stopped. Voice input remains available from the microphone.';

  @override
  String get chatVoicePlaybackFailed =>
      'Voice playback failed. The reply is available as text. Voice input remains available from the microphone.';

  @override
  String get chatVoicePlaybackFailedContinuous =>
      'Voice playback failed. The reply is available as text. Hands-free listening stopped. Voice input remains available from the microphone.';

  @override
  String get chatVoicePlaybackSessionChanged =>
      'Hermes session changed before the spoken reply finished.';

  @override
  String get chatVoicePlaybackSessionChangedContinuous =>
      'Hermes session changed before voice could re-arm. Continuous voice paused.';

  @override
  String get chatVoicePausedByLocalCommand =>
      'Continuous voice paused by local command.';

  @override
  String get chatVoiceSessionChangedContinuous =>
      'Hermes session changed. Continuous voice paused.';

  @override
  String get chatVoiceSessionChangedSpeaking =>
      'Hermes session changed. Spoken reply stopped.';

  @override
  String get chatVoiceSessionChangedCapturing =>
      'Hermes session changed. Voice capture stopped.';

  @override
  String chatVoiceContinuousPaused(String message) {
    return '$message Continuous voice paused.';
  }

  @override
  String get chatLayoutComposerSpeakingHint => 'Speaking reply…';

  @override
  String get chatLayoutComposerHint => 'Message Hermes…';

  @override
  String get chatLayoutComposerUnavailableHint => 'Chat unavailable';

  @override
  String get chatLayoutComposerTransportUnavailableHint =>
      'Chat transport unavailable';

  @override
  String get chatLayoutComposerRunRecoveryHint =>
      'Reconnect to reconcile the active run…';

  @override
  String get chatLayoutChatMenuTooltip => 'Chat menu';

  @override
  String get chatLayoutSessionsLabel => 'Sessions';

  @override
  String get chatLayoutHandsFreeVoiceLabel => 'Hands-free voice';

  @override
  String get chatLayoutEmojiTitle => 'Emoji';

  @override
  String chatLayoutInsertEmojiLabel(String value) {
    return 'Insert $value';
  }

  @override
  String get chatLayoutListeningLabel => 'Listening';

  @override
  String get chatLayoutSpeakingLabel => 'Speaking';

  @override
  String get chatLayoutHandsFreeLabel => 'Hands-free';

  @override
  String get chatLayoutContinuousVoiceLabel =>
      'Continuous voice — device STT to Hermes text';

  @override
  String chatLayoutAttachedFileLabel(String name) {
    return 'Attached file $name, ready to send';
  }

  @override
  String get chatLayoutReadyToSendLabel => 'Ready to send';

  @override
  String get chatLayoutRemoveAttachmentTooltip => 'Remove attachment';

  @override
  String get chatLayoutAttachFileTooltip => 'Attach image or text file';

  @override
  String get chatAttachmentRemoveCurrentError =>
      'Remove the current attachment before adding another.';

  @override
  String get chatAttachmentInsertedImageReadError =>
      'Could not read the inserted image.';

  @override
  String get chatAttachmentImageSizeError => 'Images must be 10 MB or smaller.';

  @override
  String get chatAttachmentPastedImageTypeError =>
      'Hermes accepts pasted PNG, JPEG, GIF, and WebP images.';

  @override
  String get chatAttachmentTextSizeError =>
      'Text files must be 256 KB or smaller.';

  @override
  String get chatAttachmentUnsupportedTypeError =>
      'Hermes accepts PNG, JPEG, GIF, WebP, and UTF-8 text files; PDFs, binary files, and videos cannot be sent.';

  @override
  String get chatAttachmentInvalidUtf8Error =>
      'Text attachments must contain valid UTF-8.';

  @override
  String chatAttachmentOpenError(String error) {
    return 'Could not open attachment: $error';
  }

  @override
  String get chatLayoutStopSpeakingTooltip => 'Stop speaking';

  @override
  String get chatLayoutSpeakAndSendTooltip => 'Start hands-free voice';

  @override
  String get chatLayoutSendTooltip => 'Send';

  @override
  String get chatLayoutVoiceOutputUnavailableTitle =>
      'Voice output unavailable';

  @override
  String get chatLayoutVoiceOutputUnavailableBody =>
      'The reply is available as text. Voice playback stopped, and hands-free listening is off. Voice input remains available from the microphone.';

  @override
  String get chatLayoutContinueInTextAction => 'Continue in text';

  @override
  String get chatLocalArtifactUndeliveredTitle =>
      'Not delivered to this device';

  @override
  String get chatLocalAudioArtifactUndeliveredBody =>
      'A tool created audio on the Hermes host, but Wing did not receive a playable audio attachment. Use the text reply instead.';

  @override
  String get chatLocalMediaArtifactUndeliveredBody =>
      'Hermes referenced media on its host, but Wing did not receive an attachment. Ask Hermes to attach the file to deliver it to this device.';

  @override
  String get chatLocalFileArtifactUndeliveredBody =>
      'Hermes created a file on its host, but Wing did not receive an attachment. Ask Hermes to attach the file to deliver it to this device.';

  @override
  String get chatShellVoicePausedBackgroundBody =>
      'Continuous voice paused while Hermes Wing is not in the foreground.';

  @override
  String get chatShellVoicePausedSwitchingAgentsBody =>
      'Continuous voice paused while switching profiles.';

  @override
  String chatShellApprovalAnswerFailedBody(String message) {
    return 'Could not answer Hermes approval: $message';
  }

  @override
  String get chatShellSwitchChatsTitle => 'Switch chats?';

  @override
  String get chatShellSwitchChatsBody =>
      'This gateway has active work or an approval. Switching closes its live streams; Hermes remains authoritative and will reconcile them when reopened.';

  @override
  String get chatShellStayAction => 'Stay';

  @override
  String get chatShellSwitchAction => 'Switch';

  @override
  String get chatShellContactClosedBody => 'Closed Hermes contact.';

  @override
  String get chatShellContactSwitchedBody => 'Switched Hermes contact.';

  @override
  String get chatShellAllChatsTooltip => 'All chats';

  @override
  String get chatShellHermesTitle => 'Hermes';

  @override
  String get chatShellConnectAnotherGatewayTooltip => 'Add gateway or profile';

  @override
  String get chatShellSessionsLabel => 'Sessions';

  @override
  String get chatShellNewSessionLabel => 'New session';

  @override
  String get chatShellMoreActionsTooltip => 'More actions';

  @override
  String get chatShellDiagnosticsLabel => 'Diagnostics';

  @override
  String get chatShellDisconnectLabel => 'Disconnect';

  @override
  String get chatShellTranscriptSessionMetadataTitle => 'Session metadata';

  @override
  String chatShellTranscriptSessionLabel(String title) {
    return 'Session: $title';
  }

  @override
  String chatShellTranscriptSessionIdLabel(String id) {
    return 'Session ID: $id';
  }

  @override
  String chatShellTranscriptMessageCountLabel(int count) {
    return 'Messages: $count';
  }

  @override
  String get chatStatusUnavailableInventoryTitle =>
      'Unavailable Hermes inventory';

  @override
  String get chatStatusDetailedHealthLabel => 'Detailed health';

  @override
  String get chatStatusModelsLabel => 'Models';

  @override
  String get chatStatusSkillsLabel => 'Skills';

  @override
  String get chatStatusToolsetsLabel => 'Toolsets';

  @override
  String get chatStatusJobsLabel => 'Jobs';

  @override
  String get chatStatusJobsTitle => 'Hermes jobs';

  @override
  String get chatStatusJobsReadOnlyAdminBody =>
      'Read-only inventory. Hermes advertises jobs admin, but Hermes Wing has not enabled mobile create/edit/delete scheduling.';

  @override
  String get chatStatusJobsReadOnlyBody =>
      'Read-only inventory. Mobile create/edit/delete scheduling is not available.';

  @override
  String get chatStatusCopyJobDetailsTooltip => 'Copy job details';

  @override
  String get chatStatusCopiedJobDetailsBody =>
      'Copied redacted Hermes job details.';

  @override
  String get chatStatusJobEnabledLabel => 'Enabled';

  @override
  String get chatStatusJobDisabledLabel => 'Disabled';

  @override
  String chatStatusJobStateLabel(String value) {
    return 'State: $value';
  }

  @override
  String chatStatusJobScheduleLabel(String value) {
    return 'Schedule: $value';
  }

  @override
  String chatStatusJobNextLabel(String value) {
    return 'Next: $value';
  }

  @override
  String chatStatusJobLastLabel(String value) {
    return 'Last: $value';
  }

  @override
  String chatStatusJobLastErrorLabel(String value) {
    return 'Last error: $value';
  }

  @override
  String get chatStatusSurfaceReadinessTitle => 'Hermes surface readiness';

  @override
  String get chatStatusSurfaceReadinessNoteBody =>
      'No mobile config, memory, schedule, or messaging-gateway mutation controls are enabled.';

  @override
  String get chatStatusCopiedSurfaceReadinessBody =>
      'Copied Hermes surface readiness summary.';

  @override
  String get chatStatusCopySummaryAction => 'Copy summary';

  @override
  String get chatStatusRunsSseEnabledLabel => 'Runs SSE enabled';

  @override
  String get chatStatusSessionChatStreamingLabel =>
      'Session chat streaming enabled';

  @override
  String get chatStatusVoiceLabel => 'Voice: device STT → Hermes';

  @override
  String chatStatusVersionLabel(String version) {
    return 'Version: $version';
  }

  @override
  String chatStatusGatewayLabel(String state) {
    return 'Gateway: $state';
  }

  @override
  String chatStatusActiveAgentsLabel(int count) {
    return 'Active profiles: $count';
  }

  @override
  String chatStatusModelsChipLabel(String names) {
    return 'Models: $names';
  }

  @override
  String get chatStatusModelsTitle => 'Hermes models';

  @override
  String chatStatusSkillsChipLabel(int count) {
    return 'Skills: $count';
  }

  @override
  String get chatStatusSkillsTitle => 'Hermes skills';

  @override
  String chatStatusToolsetsChipLabel(int count) {
    return 'Toolsets enabled: $count';
  }

  @override
  String get chatStatusToolsetsTitle => 'Hermes toolsets';

  @override
  String chatStatusJobsChipLabel(int count) {
    return 'Jobs: $count';
  }

  @override
  String chatStatusInventoryUnavailableChipLabel(int count) {
    return 'Inventory unavailable: $count';
  }

  @override
  String chatStatusSurfacesChipLabel(int deferredCount, int blockedCount) {
    return 'Surfaces: $deferredCount deferred · $blockedCount blocked';
  }

  @override
  String chatStatusAgentHeaderLabel(String model) {
    return 'Hermes Agent $model';
  }

  @override
  String chatStatusPendingApprovalsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending approvals',
    );
    return '$_temp0';
  }

  @override
  String get chatStatusApprovalRequestedTitle => 'Hermes approval requested';

  @override
  String chatStatusRiskLabel(String risk) {
    return 'Risk: $risk';
  }

  @override
  String get chatStatusApprovalResponseUnavailableBody =>
      'Hermes did not advertise approval responses for this run.';

  @override
  String get chatStatusApprovalIdMissingBody =>
      'Hermes sent this approval without an approval id, so it cannot be answered.';

  @override
  String get chatStatusAnsweringApprovalLabel => 'Answering Hermes approval…';

  @override
  String get chatStatusReviewAction => 'Review';

  @override
  String get chatStatusDismissAction => 'Dismiss';

  @override
  String get chatStatusDenyAction => 'Deny';

  @override
  String get chatStatusAllowForSessionAction => 'Allow for session';

  @override
  String get chatStatusAlwaysAllowAction => 'Always allow';

  @override
  String get chatStatusApproveOnceAction => 'Approve once';

  @override
  String get chatStatusAllowForSessionTitle => 'Allow this for the session?';

  @override
  String get chatStatusAllowForSessionBody =>
      'This may approve matching requests for the current Hermes session.';

  @override
  String get chatStatusAlwaysAllowTitle => 'Always allow this Hermes approval?';

  @override
  String get chatStatusAlwaysAllowBody =>
      'This may approve matching future requests without asking again.';

  @override
  String get chatStatusReviewApprovalTitle => 'Review Hermes approval';

  @override
  String chatStatusReviewingPendingLabel(int count) {
    return 'Reviewing 1 of $count pending approvals';
  }

  @override
  String get chatStatusPromptTruncatedBody =>
      'Prompt preview truncated for mobile review.';

  @override
  String get chatStatusRiskTruncatedBody =>
      'Risk preview truncated for mobile review.';

  @override
  String chatStatusToolCallLabel(String value) {
    return 'Tool call: $value';
  }

  @override
  String chatStatusDecisionsDisabledEndpointBody(String run_id) {
    return 'Decision buttons are disabled because Hermes did not advertise /v1/runs/$run_id/approval.';
  }

  @override
  String get chatStatusDecisionsDisabledIdBody =>
      'Decision buttons are disabled because Hermes did not include an approval id.';

  @override
  String get chatStatusCopiedApprovalDetailsBody =>
      'Copied redacted Hermes approval details.';

  @override
  String get chatStatusCopyDetailsAction => 'Copy details';

  @override
  String get chatRailSessionsTitle => 'Sessions';

  @override
  String get chatRailPinnedGroupLabel => 'Pinned';

  @override
  String get chatRailPinSessionAction => 'Pin';

  @override
  String get chatRailUnpinSessionAction => 'Unpin';

  @override
  String get chatRailHermesSessionsTitle => 'Hermes sessions';

  @override
  String get chatRailNewSessionAction => 'New';

  @override
  String get chatRailSelectAction => 'Select';

  @override
  String get chatRailSelectAllAction => 'Select all';

  @override
  String chatRailSelectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String chatRailDeleteCountAction(int count) {
    return 'Delete $count';
  }

  @override
  String get chatRailSearchSessionsLabel => 'Search sessions';

  @override
  String get chatRailSourceFilterLabel => 'Filter by source';

  @override
  String get chatRailAllSourcesLabel => 'All sources';

  @override
  String get chatRailClearSearchTooltip => 'Clear search';

  @override
  String chatRailSessionCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String chatRailShowingSessionCountLabel(int total, int visible) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Showing $visible of $total sessions',
      one: 'Showing $visible of $total session',
    );
    return '$_temp0';
  }

  @override
  String get chatRailNoSessionsBody =>
      'No sessions yet. Create one to start a Hermes chat.';

  @override
  String chatRailNoSessionsMatchBody(String query) {
    return 'No sessions match “$query”.';
  }

  @override
  String get chatRailNoHermesSessionsBody => 'No Hermes sessions yet.';

  @override
  String chatRailNoHermesSessionsMatchBody(String query) {
    return 'No Hermes sessions match “$query”.';
  }

  @override
  String get chatRailActiveHermesSessionLabel => 'Active Hermes session';

  @override
  String get chatRailCycleActiveSessionsTooltip =>
      'Switch live chats · Ctrl+Tab or Ctrl/Command+1–9';

  @override
  String get chatRailActiveLabel => 'Active';

  @override
  String get chatRailStatusStreamingLabel => 'Streaming';

  @override
  String get chatRailNewReplyLabel => 'New reply';

  @override
  String get chatRailStatusReadyLabel => 'Ready';

  @override
  String get chatRailStatusTransportUnavailableLabel => 'Transport unavailable';

  @override
  String chatRailMessageCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String chatRailTileMessageCountLabel(int count) {
    return '$count messages';
  }

  @override
  String get chatRailEmptyStateTitle => 'How can Hermes help today?';

  @override
  String get chatRailEmptyStateBody =>
      'Start a session with text or local voice. Hermes Wing keeps the mobile chat flow Telegram-fast while Hermes handles runs, tools, and approvals.';

  @override
  String get chatRailPromptSummarizeHelpLabel =>
      'Summarize what you can help me do.';

  @override
  String get chatRailPromptListSkillsLabel =>
      'List my available Hermes skills.';

  @override
  String get chatRailPromptPlanTaskLabel => 'Plan my next coding task.';

  @override
  String get chatRailPromptExplainSessionLabel =>
      'Explain the current session state.';

  @override
  String get chatRailStopAction => 'Stop';

  @override
  String chatRailForkedFromLabel(String sessionId) {
    return 'Forked from $sessionId';
  }

  @override
  String chatRailLastActiveLabel(String timestamp) {
    return 'Last active $timestamp';
  }

  @override
  String get chatRailSessionActionsTooltip => 'Session actions';

  @override
  String get chatRailViewDetailsAction => 'View details';

  @override
  String get chatRailCopyDetailsAction => 'Copy details';

  @override
  String get chatRailRenameAction => 'Rename';

  @override
  String get chatRailBranchAction => 'Branch';

  @override
  String get chatRailDeleteAction => 'Delete';

  @override
  String get chatRailCopiedSessionDetailsBody =>
      'Copied redacted Hermes session details.';

  @override
  String get chatRailSessionDetailsTitle => 'Session details';

  @override
  String get chatRailSessionDetailsHeaderLabel => 'Hermes session';

  @override
  String chatRailDetailTitleLabel(String value) {
    return 'Title: $value';
  }

  @override
  String chatRailDetailIdLabel(String value) {
    return 'ID: $value';
  }

  @override
  String chatRailDetailActiveLabel(String value) {
    return 'Active: $value';
  }

  @override
  String chatRailDetailMessagesLabel(int count) {
    return 'Messages: $count';
  }

  @override
  String chatRailDetailToolCallsLabel(int count) {
    return 'Tool calls: $count';
  }

  @override
  String chatRailDetailApiCallsLabel(int count) {
    return 'API calls: $count';
  }

  @override
  String chatRailDetailInputTokensLabel(int count) {
    return 'Session input tokens: $count';
  }

  @override
  String chatRailDetailOutputTokensLabel(int count) {
    return 'Session output tokens: $count';
  }

  @override
  String chatRailDetailCacheReadTokensLabel(int count) {
    return 'Session cache read tokens: $count';
  }

  @override
  String chatRailDetailCacheWriteTokensLabel(int count) {
    return 'Session cache write tokens: $count';
  }

  @override
  String chatRailDetailReasoningTokensLabel(int count) {
    return 'Session reasoning tokens: $count';
  }

  @override
  String chatRailDetailActualCostLabel(String cost) {
    return 'Actual cost (USD): $cost';
  }

  @override
  String chatRailDetailEstimatedCostLabel(String cost) {
    return 'Estimated cost (USD): $cost';
  }

  @override
  String chatRailDetailStartedLabel(String value) {
    return 'Started: $value';
  }

  @override
  String chatRailDetailEndedLabel(String value) {
    return 'Ended: $value';
  }

  @override
  String chatRailDetailEndReasonLabel(String value) {
    return 'End reason: $value';
  }

  @override
  String chatRailDetailSystemPromptSnapshotLabel(String value) {
    return 'System prompt snapshot: $value';
  }

  @override
  String chatRailDetailModelConfigSnapshotLabel(String value) {
    return 'Model config snapshot: $value';
  }

  @override
  String get chatRailDetailYesLabel => 'yes';

  @override
  String get chatRailDetailNoLabel => 'no';

  @override
  String chatRailDetailForkedFromLabel(String value) {
    return 'Forked from: $value';
  }

  @override
  String chatRailDetailLastActiveLabel(String value) {
    return 'Last active: $value';
  }

  @override
  String get modelPresetsLabel => 'Presets';

  @override
  String get modelPresetSaveAction => 'Save preset';

  @override
  String get modelPresetSaveTitle => 'Save model preset';

  @override
  String get modelPresetNameLabel => 'Preset name';

  @override
  String get modelPresetUnavailableBody => 'Not in this gateway\'s catalog';

  @override
  String credentialProbeLatency(int ms) {
    return '$ms ms';
  }

  @override
  String credentialProbeModelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models available',
      one: '1 model available',
    );
    return '$_temp0';
  }

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsChatSection => 'Chat';

  @override
  String get chatSpellcheckTitle => 'Check spelling';

  @override
  String get chatSpellcheckSubtitle =>
      'Use the platform spell checker while composing messages';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themePaletteWing => 'Wing';

  @override
  String get themePaletteIndigo => 'Indigo';

  @override
  String get themePaletteForest => 'Forest';

  @override
  String get themePaletteAmber => 'Amber';

  @override
  String get themePaletteMulberry => 'Mulberry';

  @override
  String get tipMoreDestinations =>
      'Chat, Discover, Office, and Tasks are below. Profiles, Providers, Tools, Memory, and Gateway administration live under More.';

  @override
  String get tipVoice =>
      'Tap the microphone for hands-free voice. Long-press to dictate for review. Wing reports listening and playback separately.';

  @override
  String get tipApprovals =>
      'Hermes asks before sensitive actions. Review each request, then approve once, allow for the session, always allow, or deny.';

  @override
  String get tipDismissTooltip => 'Dismiss tip';

  @override
  String get toolsLoading => 'Loading tools';

  @override
  String get gatewayLoading => 'Loading gateway status';

  @override
  String get schedulesLoading => 'Loading schedules';

  @override
  String get localSetupTitle => 'Set up Hermes on this Linux computer';

  @override
  String get localSetupBody =>
      'Hermes Wing can detect, install, or adopt Hermes Agent here. Installation changes are shown before they run. Profiles, providers, Tailscale, tools, channels, and schedules remain managed by Hermes after connection.';

  @override
  String get localSetupDetecting => 'Checking this computer for Hermes Agent…';

  @override
  String get localSetupMissingTitle => 'Hermes Agent is not installed';

  @override
  String get localSetupMissingBody =>
      'Install the verified Hermes Agent release for your user account, secure the local API, and start the gateway.';

  @override
  String get localSetupReadyTitle => 'Hermes Agent is ready';

  @override
  String get localSetupReadyBody =>
      'Adopt this existing installation without replacing its profiles, providers, or configuration.';

  @override
  String get localSetupUnhealthyTitle => 'Hermes Agent needs repair';

  @override
  String get localSetupUnhealthyBody =>
      'Hermes was found but did not pass its version check. Setup can reinstall the verified runtime without intentionally replacing Hermes-owned configuration.';

  @override
  String get localSetupAction => 'Set up Hermes on this computer';

  @override
  String get localSetupInstallAction => 'Install Hermes Agent here';

  @override
  String get localSetupAdoptAction => 'Adopt this installation';

  @override
  String get localSetupRepairAction => 'Repair Hermes Agent';

  @override
  String get localSetupInstalling =>
      'Installing or adopting Hermes Agent and starting its gateway…';

  @override
  String get localSetupCompleteTitle => 'Hermes gateway is ready';

  @override
  String get localSetupCompleteBody =>
      'Local installation and gateway startup are verified. Continue to pairing before managing Hermes capabilities.';

  @override
  String get localSetupContinueAction => 'Continue to pairing';

  @override
  String get localSetupRetryAction => 'Check again';

  @override
  String get localSetupConsentTitle => 'Allow local Hermes setup?';

  @override
  String get localSetupConsentBody =>
      'Wing Link will run a verified Hermes installer when needed, create or update user-level service files, secure local API access, and start the Hermes gateway. It will not configure profiles or providers.';

  @override
  String get localSetupConsentAction => 'Run setup';

  @override
  String get termuxSetupTitle => 'Install Hermes Agent on this phone';

  @override
  String get termuxSetupBody =>
      'Hermes Wing uses Hermes Agent’s official verified installer in Termux. Wing never runs commands inside Termux.';

  @override
  String get termuxInstallAction => 'Install Termux';

  @override
  String get termuxInstallGuideFailedMessage =>
      'The Termux installation guide could not be opened. Open it manually at github.com/termux/termux-app.';

  @override
  String get termuxCopyAction => 'Copy setup command';

  @override
  String get termuxCopiedMessage =>
      'Setup command copied. Open Termux and run it without changes.';

  @override
  String get termuxCopyFailedMessage =>
      'The setup command could not be copied. Select the command and copy it manually.';

  @override
  String get termuxMetadataUnavailable =>
      'This build cannot install the matching Wing Link release.';

  @override
  String get termuxRunStep =>
      'Open Termux and run the copied command. Keep Termux in the foreground while setup finishes.';

  @override
  String get termuxReturnStep =>
      'Tap the local link shown by Termux, then return here to review the connection.';

  @override
  String get termuxTierTwoNotice =>
      'Android / Termux is Tier 2. Android may stop background processes; rerun the same command to recover.';

  @override
  String get enrollInstallOnPhoneAction => 'Install Hermes Agent on this phone';

  @override
  String get enrollConnectedLocalBody =>
      'Hermes Agent is connected on this phone. To configure the existing default profile, run hermes setup in Termux. To configure more in Wing, create a new profile with its provider and model, approve the request in Termux, retry the unchanged request, then pair once more to enroll that profile.';

  @override
  String profileApprovalRequired(String approvalId) {
    return 'Approve this request locally on the Wing Link host, then retry the unchanged setup. Run wing-link approvals list, then wing-link approvals approve $approvalId.';
  }

  @override
  String get profileRetryApprovedSetup => 'Retry approved setup';

  @override
  String get profileCancelSetup => 'Cancel setup';

  @override
  String get profileApprovalExpired =>
      'The local approval expired. Enter the credential again to start a new request.';
}
