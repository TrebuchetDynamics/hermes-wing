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
