import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing'**
  String get appTitle;

  /// No description provided for @hermesDestination.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get hermesDestination;

  /// No description provided for @agentsDestination.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentsDestination;

  /// No description provided for @settingsDestination.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsDestination;

  /// No description provided for @moreDestinations.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreDestinations;

  /// No description provided for @openMoreDestinations.
  ///
  /// In en, this message translates to:
  /// **'Open more destinations'**
  String get openMoreDestinations;

  /// No description provided for @agentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentsTitle;

  /// No description provided for @agentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Hermes works for each role.'**
  String get agentsSubtitle;

  /// No description provided for @newAgent.
  ///
  /// In en, this message translates to:
  /// **'New Agent'**
  String get newAgent;

  /// No description provided for @agentsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading agents'**
  String get agentsLoading;

  /// No description provided for @agentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No agents available'**
  String get agentsEmptyTitle;

  /// No description provided for @agentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with profile access to view Hermes agents.'**
  String get agentsEmptyBody;

  /// No description provided for @agentsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents unavailable'**
  String get agentsUnavailableTitle;

  /// No description provided for @agentsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Update Hermes Agent and reconnect this gateway with profile permissions.'**
  String get agentsUnavailableBody;

  /// No description provided for @agentsConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Agents could not be loaded from Hermes.'**
  String get agentsConnectionError;

  /// No description provided for @selectedAgent.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedAgent;

  /// No description provided for @defaultAgent.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAgent;

  /// No description provided for @readOnlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Read-only access'**
  String get readOnlyAccess;

  /// No description provided for @agentStableId.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String agentStableId(String id);

  /// No description provided for @agentSkillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No skills} =1{1 skill} other{{count} skills}}'**
  String agentSkillsCount(int count);

  /// No description provided for @agentGatewayRunning.
  ///
  /// In en, this message translates to:
  /// **'Gateway running'**
  String get agentGatewayRunning;

  /// No description provided for @agentGatewayOff.
  ///
  /// In en, this message translates to:
  /// **'Gateway off'**
  String get agentGatewayOff;

  /// No description provided for @agentNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get agentNoModel;

  /// No description provided for @chatWithAgent.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatWithAgent;

  /// No description provided for @switchingAgent.
  ///
  /// In en, this message translates to:
  /// **'Switching…'**
  String get switchingAgent;

  /// No description provided for @editAgent.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAgent;

  /// No description provided for @createAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Create agent'**
  String get createAgentTitle;

  /// No description provided for @agentDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Agent name'**
  String get agentDisplayName;

  /// No description provided for @agentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an agent name.'**
  String get agentNameRequired;

  /// No description provided for @cloneFromAgent.
  ///
  /// In en, this message translates to:
  /// **'Clone from'**
  String get cloneFromAgent;

  /// No description provided for @startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get startFresh;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @doneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneAction;

  /// No description provided for @renameAgent.
  ///
  /// In en, this message translates to:
  /// **'Rename agent'**
  String get renameAgent;

  /// No description provided for @editPersona.
  ///
  /// In en, this message translates to:
  /// **'Edit persona'**
  String get editPersona;

  /// No description provided for @personaLabel.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get personaLabel;

  /// No description provided for @personaHint.
  ///
  /// In en, this message translates to:
  /// **'Describe this agent’s role, voice, and working style.'**
  String get personaHint;

  /// No description provided for @deleteAgent.
  ///
  /// In en, this message translates to:
  /// **'Delete agent'**
  String get deleteAgent;

  /// No description provided for @deleteAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteAgentTitle(String name);

  /// No description provided for @deleteAgentBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the agent from Hermes. Type its display name to confirm.'**
  String get deleteAgentBody;

  /// No description provided for @deleteConfirmationLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent name'**
  String get deleteConfirmationLabel;

  /// No description provided for @deleteConfirmationMismatch.
  ///
  /// In en, this message translates to:
  /// **'The name does not match.'**
  String get deleteConfirmationMismatch;

  /// No description provided for @defaultAgentCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'The default agent cannot be deleted.'**
  String get defaultAgentCannotDelete;

  /// No description provided for @profileOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Hermes could not complete that profile change.'**
  String get profileOperationFailed;

  /// No description provided for @profileRevisionConflict.
  ///
  /// In en, this message translates to:
  /// **'This agent changed elsewhere. The latest version has been loaded; review it before trying again.'**
  String get profileRevisionConflict;

  /// No description provided for @switchAgent.
  ///
  /// In en, this message translates to:
  /// **'Switch agent'**
  String get switchAgent;

  /// No description provided for @manageAgents.
  ///
  /// In en, this message translates to:
  /// **'Manage agents'**
  String get manageAgents;

  /// No description provided for @switchAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch agent'**
  String get switchAgentTitle;

  /// No description provided for @switchAgentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch agent: {message}'**
  String switchAgentFailed(String message);

  /// No description provided for @providersDestination.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providersDestination;

  /// No description provided for @toolsDestination.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsDestination;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Installed skills and enabled toolsets advertised by this gateway.'**
  String get toolsSubtitle;

  /// No description provided for @toolsConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Open a saved gateway chat before viewing its tool inventory.'**
  String get toolsConnectionRequiredBody;

  /// No description provided for @toolsConnectionErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Tool inventory could not be loaded from Hermes.'**
  String get toolsConnectionErrorBody;

  /// No description provided for @gatewayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gatewayLabel;

  /// No description provided for @selectGatewayHint.
  ///
  /// In en, this message translates to:
  /// **'Select gateway'**
  String get selectGatewayHint;

  /// No description provided for @toolsGatewayHelp.
  ///
  /// In en, this message translates to:
  /// **'View tool inventory from the selected gateway.'**
  String get toolsGatewayHelp;

  /// No description provided for @gatewayConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to this gateway.'**
  String get gatewayConnectFailed;

  /// No description provided for @installedSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Installed skills'**
  String get installedSkillsTitle;

  /// No description provided for @enabledToolsetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled toolsets'**
  String get enabledToolsetsTitle;

  /// No description provided for @skillsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This gateway did not advertise installed skill inventory.'**
  String get skillsUnavailableBody;

  /// No description provided for @toolsetsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This gateway did not advertise enabled toolset inventory.'**
  String get toolsetsUnavailableBody;

  /// No description provided for @skillsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No installed skills were reported.'**
  String get skillsEmptyBody;

  /// No description provided for @searchInstalledSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search installed skills'**
  String get searchInstalledSkillsLabel;

  /// No description provided for @noSkillsMatchBody.
  ///
  /// In en, this message translates to:
  /// **'No installed skills match this search.'**
  String get noSkillsMatchBody;

  /// No description provided for @toolsetsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No enabled toolsets were reported.'**
  String get toolsetsEmptyBody;

  /// No description provided for @skillsLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Installed skills could not be loaded from Hermes.'**
  String get skillsLoadFailedBody;

  /// No description provided for @toolsetsLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Enabled toolsets could not be loaded from Hermes.'**
  String get toolsetsLoadFailedBody;

  /// No description provided for @schedulesDestination.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedulesDestination;

  /// No description provided for @schedulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedulesTitle;

  /// No description provided for @schedulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled jobs advertised by the selected gateway and agent.'**
  String get schedulesSubtitle;

  /// No description provided for @schedulesGatewayHelp.
  ///
  /// In en, this message translates to:
  /// **'View schedules from the selected gateway.'**
  String get schedulesGatewayHelp;

  /// No description provided for @schedulesConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Open a saved gateway chat before viewing its schedules.'**
  String get schedulesConnectionRequiredBody;

  /// No description provided for @schedulesConnectionErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Schedules could not be loaded from Hermes.'**
  String get schedulesConnectionErrorBody;

  /// No description provided for @schedulesUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This gateway did not advertise scheduled-job inventory.'**
  String get schedulesUnavailableBody;

  /// No description provided for @schedulesLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Schedules could not be loaded from Hermes.'**
  String get schedulesLoadFailedBody;

  /// No description provided for @schedulesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No scheduled jobs were reported for this agent.'**
  String get schedulesEmptyBody;

  /// No description provided for @schedulesReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Read-only schedule inventory. Create, pause, trigger, and delete remain hidden until this gateway advertises exact scoped administration contracts.'**
  String get schedulesReadOnlyNote;

  /// No description provided for @schedulesRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh schedules'**
  String get schedulesRefreshTooltip;

  /// No description provided for @scheduleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get scheduleEnabled;

  /// No description provided for @scheduleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get scheduleDisabled;

  /// No description provided for @scheduleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get scheduleActive;

  /// No description provided for @schedulePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get schedulePaused;

  /// No description provided for @scheduleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get scheduleCompleted;

  /// No description provided for @scheduleStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get scheduleStateLabel;

  /// No description provided for @scheduleExpressionLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleExpressionLabel;

  /// No description provided for @scheduleNextRunLabel.
  ///
  /// In en, this message translates to:
  /// **'Next run'**
  String get scheduleNextRunLabel;

  /// No description provided for @scheduleLastRunLabel.
  ///
  /// In en, this message translates to:
  /// **'Last run'**
  String get scheduleLastRunLabel;

  /// No description provided for @scheduleLastErrorNotice.
  ///
  /// In en, this message translates to:
  /// **'Last run reported an error.'**
  String get scheduleLastErrorNotice;

  /// No description provided for @gatewayDestination.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gatewayDestination;

  /// No description provided for @gatewayStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gatewayStatusTitle;

  /// No description provided for @gatewayStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bounded health status advertised by the selected Hermes gateway.'**
  String get gatewayStatusSubtitle;

  /// No description provided for @gatewayStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'View status from the selected gateway.'**
  String get gatewayStatusHelp;

  /// No description provided for @gatewayStatusConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Open a saved gateway chat before viewing gateway status.'**
  String get gatewayStatusConnectionRequiredBody;

  /// No description provided for @gatewayStatusConnectionErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Gateway status could not be loaded from Hermes.'**
  String get gatewayStatusConnectionErrorBody;

  /// No description provided for @gatewayStatusUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This gateway did not advertise detailed health status.'**
  String get gatewayStatusUnavailableBody;

  /// No description provided for @gatewayStatusLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Detailed gateway status could not be loaded from Hermes.'**
  String get gatewayStatusLoadFailedBody;

  /// No description provided for @gatewayStatusReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Read-only gateway status. Lifecycle, logs, and messaging-platform administration remain hidden until exact scoped contracts are advertised.'**
  String get gatewayStatusReadOnlyNote;

  /// No description provided for @gatewayStatusRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh gateway status'**
  String get gatewayStatusRefreshTooltip;

  /// No description provided for @gatewayHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get gatewayHealthy;

  /// No description provided for @gatewayNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get gatewayNeedsAttention;

  /// No description provided for @gatewayPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get gatewayPlatformLabel;

  /// No description provided for @gatewayVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get gatewayVersionLabel;

  /// No description provided for @gatewayRuntimeStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime state'**
  String get gatewayRuntimeStateLabel;

  /// No description provided for @gatewayActiveAgentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active agents'**
  String get gatewayActiveAgentsLabel;

  /// No description provided for @providersTitle.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providersTitle;

  /// No description provided for @providersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set provider credentials and choose models for this agent.'**
  String get providersSubtitle;

  /// No description provided for @providersGatewayHelp.
  ///
  /// In en, this message translates to:
  /// **'Manage providers and models on the selected gateway.'**
  String get providersGatewayHelp;

  /// No description provided for @providersLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading providers'**
  String get providersLoading;

  /// No description provided for @providersConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Providers could not be loaded from Hermes.'**
  String get providersConnectionError;

  /// No description provided for @providersUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Providers unavailable'**
  String get providersUnavailableTitle;

  /// No description provided for @providersUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes did not advertise provider access for this connection.'**
  String get providersUnavailableBody;

  /// No description provided for @providersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No providers available'**
  String get providersEmptyTitle;

  /// No description provided for @providersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with provider access to manage credentials.'**
  String get providersEmptyBody;

  /// No description provided for @providerConfiguredBadge.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get providerConfiguredBadge;

  /// No description provided for @providerNotConfiguredBadge.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get providerNotConfiguredBadge;

  /// No description provided for @providerKeyHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Key {hint}'**
  String providerKeyHintLabel(String hint);

  /// No description provided for @manageCredentialAction.
  ///
  /// In en, this message translates to:
  /// **'Manage credential'**
  String get manageCredentialAction;

  /// No description provided for @providerOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The provider operation could not be completed.'**
  String get providerOperationFailed;

  /// No description provided for @modelSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Model selection'**
  String get modelSelectionTitle;

  /// No description provided for @modelSelectionUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes did not advertise model access for this connection.'**
  String get modelSelectionUnavailableBody;

  /// No description provided for @runtimeModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime models'**
  String get runtimeModelsTitle;

  /// No description provided for @runtimeModelsBody.
  ///
  /// In en, this message translates to:
  /// **'Read-only models advertised by this gateway. Provider credentials and assignments remain unavailable.'**
  String get runtimeModelsBody;

  /// No description provided for @runtimeModelsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No runtime models were reported.'**
  String get runtimeModelsEmptyBody;

  /// No description provided for @activeModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Active model'**
  String get activeModelLabel;

  /// No description provided for @noModelAssigned.
  ///
  /// In en, this message translates to:
  /// **'No model assigned'**
  String get noModelAssigned;

  /// No description provided for @auxiliaryModelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Auxiliary models'**
  String get auxiliaryModelsLabel;

  /// No description provided for @auxiliaryModelSummary.
  ///
  /// In en, this message translates to:
  /// **'{task}: {provider} / {model}'**
  String auxiliaryModelSummary(String task, String provider, String model);

  /// No description provided for @chooseModelAction.
  ///
  /// In en, this message translates to:
  /// **'Choose model'**
  String get chooseModelAction;

  /// No description provided for @refreshCatalogAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh catalog'**
  String get refreshCatalogAction;

  /// No description provided for @modelPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get modelPickerTitle;

  /// No description provided for @modelSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot'**
  String get modelSlotLabel;

  /// No description provided for @modelSlotMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get modelSlotMain;

  /// No description provided for @modelProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get modelProviderLabel;

  /// No description provided for @modelNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelNameLabel;

  /// No description provided for @assignModelAction.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignModelAction;

  /// No description provided for @modelCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No models in the catalog. Refresh to fetch the latest.'**
  String get modelCatalogEmpty;

  /// No description provided for @modelAssignmentFailed.
  ///
  /// In en, this message translates to:
  /// **'The model assignment could not be saved.'**
  String get modelAssignmentFailed;

  /// No description provided for @modelRevisionConflict.
  ///
  /// In en, this message translates to:
  /// **'The model selection changed elsewhere. Reopen the picker to try again.'**
  String get modelRevisionConflict;

  /// No description provided for @credentialSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{provider} credential'**
  String credentialSheetTitle(String provider);

  /// No description provided for @credentialWriteOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing can set this credential but never shows a stored key.'**
  String get credentialWriteOnlyNotice;

  /// No description provided for @credentialEnvVarLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment variable'**
  String get credentialEnvVarLabel;

  /// No description provided for @credentialValueLabel.
  ///
  /// In en, this message translates to:
  /// **'New secret value'**
  String get credentialValueLabel;

  /// No description provided for @credentialValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a value to set.'**
  String get credentialValueRequired;

  /// No description provided for @setCredentialAction.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setCredentialAction;

  /// No description provided for @removeCredentialAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeCredentialAction;

  /// No description provided for @validateCredentialAction.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validateCredentialAction;

  /// No description provided for @credentialConfiguredStatus.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get credentialConfiguredStatus;

  /// No description provided for @credentialNotConfiguredStatus.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get credentialNotConfiguredStatus;

  /// No description provided for @credentialOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The credential operation could not be completed.'**
  String get credentialOperationFailed;

  /// No description provided for @copyTranscriptAction.
  ///
  /// In en, this message translates to:
  /// **'Copy transcript'**
  String get copyTranscriptAction;

  /// No description provided for @copyTranscriptDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a portable transcript format.'**
  String get copyTranscriptDescription;

  /// No description provided for @copyAsTextAction.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get copyAsTextAction;

  /// No description provided for @copyAsMarkdownAction.
  ///
  /// In en, this message translates to:
  /// **'Copy as Markdown'**
  String get copyAsMarkdownAction;

  /// No description provided for @transcriptFormatText.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get transcriptFormatText;

  /// No description provided for @transcriptFormatMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get transcriptFormatMarkdown;

  /// No description provided for @transcriptCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Transcript copied as {format}'**
  String transcriptCopiedMessage(String format);

  /// No description provided for @transcriptAuthorYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get transcriptAuthorYou;

  /// No description provided for @transcriptAuthorHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get transcriptAuthorHermes;

  /// No description provided for @transcriptAuthorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get transcriptAuthorSystem;

  /// No description provided for @transcriptToolHeading.
  ///
  /// In en, this message translates to:
  /// **'Tool: {name}'**
  String transcriptToolHeading(String name);

  /// No description provided for @transcriptToolStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String transcriptToolStatus(String status);

  /// No description provided for @sessionsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sessionsToday;

  /// No description provided for @sessionsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get sessionsYesterday;

  /// No description provided for @sessionsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get sessionsThisWeek;

  /// No description provided for @sessionsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get sessionsEarlier;

  /// No description provided for @sessionUnknownSource.
  ///
  /// In en, this message translates to:
  /// **'Unknown source'**
  String get sessionUnknownSource;

  /// No description provided for @sessionSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String sessionSourceLabel(String source);

  /// No description provided for @sessionModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model: {model}'**
  String sessionModelLabel(String model);

  /// No description provided for @sessionModelNotReported.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get sessionModelNotReported;

  /// No description provided for @transcriptImageFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get transcriptImageFallbackLabel;

  /// No description provided for @transcriptImageNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'image not loaded'**
  String get transcriptImageNotLoaded;

  /// No description provided for @copyCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeAction;

  /// No description provided for @codeCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopiedMessage;

  /// No description provided for @showMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMoreAction;

  /// No description provided for @showLessAction.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLessAction;

  /// No description provided for @reasoningTitle.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoningTitle;

  /// No description provided for @localCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wing commands'**
  String get localCommandsTitle;

  /// No description provided for @localCommandsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Wing commands'**
  String get localCommandsHelpTitle;

  /// No description provided for @localCommandsHelpBody.
  ///
  /// In en, this message translates to:
  /// **'These commands run on this device and are never sent to Hermes Agent.'**
  String get localCommandsHelpBody;

  /// No description provided for @localCommandHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Show Wing-owned commands.'**
  String get localCommandHelpDescription;

  /// No description provided for @localCommandToolsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open installed skills and toolsets.'**
  String get localCommandToolsDescription;

  /// No description provided for @localCommandSkillsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open installed skills.'**
  String get localCommandSkillsDescription;

  /// No description provided for @localCommandGatewayDescription.
  ///
  /// In en, this message translates to:
  /// **'Open gateway status.'**
  String get localCommandGatewayDescription;

  /// No description provided for @localCommandAgentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open gateway-scoped agents.'**
  String get localCommandAgentsDescription;

  /// No description provided for @localCommandProvidersDescription.
  ///
  /// In en, this message translates to:
  /// **'Open providers and models.'**
  String get localCommandProvidersDescription;

  /// No description provided for @localCommandModelDescription.
  ///
  /// In en, this message translates to:
  /// **'Open provider and model management.'**
  String get localCommandModelDescription;

  /// No description provided for @localCommandSchedulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Open gateway schedules.'**
  String get localCommandSchedulesDescription;

  /// No description provided for @localCommandPersonaDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the selected agent persona.'**
  String get localCommandPersonaDescription;

  /// No description provided for @localCommandVersionDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the connected gateway version.'**
  String get localCommandVersionDescription;

  /// No description provided for @gatewayVersionSummary.
  ///
  /// In en, this message translates to:
  /// **'Gateway version: {platform} {version}'**
  String gatewayVersionSummary(String platform, String version);

  /// No description provided for @gatewayVersionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Gateway version is unavailable.'**
  String get gatewayVersionUnavailable;

  /// No description provided for @gatewayVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'version unknown'**
  String get gatewayVersionUnknown;

  /// No description provided for @profilePersonaTitle.
  ///
  /// In en, this message translates to:
  /// **'{profile} persona'**
  String profilePersonaTitle(String profile);

  /// No description provided for @profilePersonaEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This agent has no persona content.'**
  String get profilePersonaEmptyBody;

  /// No description provided for @profilePersonaLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Persona could not be loaded: {error}'**
  String profilePersonaLoadFailed(String error);

  /// No description provided for @localCommandNewDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a new Hermes session.'**
  String get localCommandNewDescription;

  /// No description provided for @localCommandSessionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open session history.'**
  String get localCommandSessionsDescription;

  /// No description provided for @localCommandClearDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear the current draft.'**
  String get localCommandClearDescription;

  /// No description provided for @localCommandSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open Wing settings.'**
  String get localCommandSettingsDescription;

  /// No description provided for @localCommandUsageDescription.
  ///
  /// In en, this message translates to:
  /// **'Show token usage for the latest reply.'**
  String get localCommandUsageDescription;

  /// No description provided for @noRunTokenUsageMessage.
  ///
  /// In en, this message translates to:
  /// **'No server-reported token usage is available yet.'**
  String get noRunTokenUsageMessage;

  /// No description provided for @runTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'{inputTokens} in · {outputTokens} out · {totalTokens} total tokens'**
  String runTokenUsage(int inputTokens, int outputTokens, int totalTokens);

  /// No description provided for @transcriptRunTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage: {inputTokens} input · {outputTokens} output · {totalTokens} total tokens'**
  String transcriptRunTokenUsage(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  );

  /// No description provided for @runTokenUsageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Token usage: {inputTokens} input, {outputTokens} output, {totalTokens} total'**
  String runTokenUsageSemantics(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  );

  /// No description provided for @auxiliaryTaskVision.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get auxiliaryTaskVision;

  /// No description provided for @auxiliaryTaskWebExtract.
  ///
  /// In en, this message translates to:
  /// **'Web extract'**
  String get auxiliaryTaskWebExtract;

  /// No description provided for @auxiliaryTaskCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get auxiliaryTaskCompression;

  /// No description provided for @auxiliaryTaskSkillsHub.
  ///
  /// In en, this message translates to:
  /// **'Skills hub'**
  String get auxiliaryTaskSkillsHub;

  /// No description provided for @auxiliaryTaskApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get auxiliaryTaskApproval;

  /// No description provided for @auxiliaryTaskMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get auxiliaryTaskMcp;

  /// No description provided for @auxiliaryTaskTitleGeneration.
  ///
  /// In en, this message translates to:
  /// **'Title generation'**
  String get auxiliaryTaskTitleGeneration;

  /// No description provided for @auxiliaryTaskTriageSpecifier.
  ///
  /// In en, this message translates to:
  /// **'Triage specifier'**
  String get auxiliaryTaskTriageSpecifier;

  /// No description provided for @auxiliaryTaskKanbanDecomposer.
  ///
  /// In en, this message translates to:
  /// **'Kanban decomposer'**
  String get auxiliaryTaskKanbanDecomposer;

  /// No description provided for @auxiliaryTaskProfileDescriber.
  ///
  /// In en, this message translates to:
  /// **'Profile describer'**
  String get auxiliaryTaskProfileDescriber;

  /// No description provided for @auxiliaryTaskCurator.
  ///
  /// In en, this message translates to:
  /// **'Curator'**
  String get auxiliaryTaskCurator;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
