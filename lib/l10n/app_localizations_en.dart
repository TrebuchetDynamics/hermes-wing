// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Navivox';

  @override
  String get hermesDestination => 'Hermes';

  @override
  String get agentsDestination => 'Agents';

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
      'Hermes did not advertise profile access for this connection.';

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
  String get saveAction => 'Save';

  @override
  String get doneAction => 'Done';

  @override
  String get renameAgent => 'Rename agent';

  @override
  String get editPersona => 'Edit persona';

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
  String get deleteConfirmationMismatch => 'The name does not match.';

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
  String get manageAgents => 'Manage agents';

  @override
  String get switchAgentTitle => 'Switch agent';

  @override
  String switchAgentFailed(String message) {
    return 'Could not switch agent: $message';
  }

  @override
  String get providersDestination => 'Providers';

  @override
  String get providersTitle => 'Providers';

  @override
  String get providersSubtitle =>
      'Set provider credentials and choose models for this agent.';

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
      'Navivox can set this credential but never shows a stored key.';

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
}
