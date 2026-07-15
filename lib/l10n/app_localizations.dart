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
  /// **'Navivox'**
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
  /// **'Hermes did not advertise profile access for this connection.'**
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
  /// **'Navivox can set this credential but never shows a stored key.'**
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
