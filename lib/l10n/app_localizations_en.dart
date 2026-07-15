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
}
