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

  /// No description provided for @managedSshSaveTarget.
  ///
  /// In en, this message translates to:
  /// **'Save SSH settings'**
  String get managedSshSaveTarget;

  /// No description provided for @managedSshLoadTarget.
  ///
  /// In en, this message translates to:
  /// **'Use saved SSH settings'**
  String get managedSshLoadTarget;

  /// No description provided for @managedSshTargetBody.
  ///
  /// In en, this message translates to:
  /// **'Save one SSH destination and Agent transport on this device. Passwords, keys and Agent credentials are not saved. Loading settings does not connect.'**
  String get managedSshTargetBody;

  /// No description provided for @managedSshTargetSaved.
  ///
  /// In en, this message translates to:
  /// **'SSH settings saved securely. Authentication is still required.'**
  String get managedSshTargetSaved;

  /// No description provided for @managedSshTargetLoaded.
  ///
  /// In en, this message translates to:
  /// **'Saved SSH settings loaded. Enter credentials, then Connect.'**
  String get managedSshTargetLoaded;

  /// No description provided for @managedSshTargetMissing.
  ///
  /// In en, this message translates to:
  /// **'No saved SSH settings on this device.'**
  String get managedSshTargetMissing;

  /// No description provided for @managedSshTargetFailure.
  ///
  /// In en, this message translates to:
  /// **'SSH settings could not be saved or loaded securely.'**
  String get managedSshTargetFailure;

  /// No description provided for @managedSshServeReads.
  ///
  /// In en, this message translates to:
  /// **'Read Hermes serve through SSH'**
  String get managedSshServeReads;

  /// No description provided for @managedSshServeReadsBody.
  ///
  /// In en, this message translates to:
  /// **'Use the host-provided serve session token, not API_SERVER_KEY. Reads profiles, sessions and history. Chat requires separate ticket authentication. SSH settings can be saved separately; credentials and automatic restoration are not saved. No automatic protocol fallback.'**
  String get managedSshServeReadsBody;

  /// No description provided for @localServeReadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Read an already-running Hermes serve backend'**
  String get localServeReadsLabel;

  /// No description provided for @localServeReadsBody.
  ///
  /// In en, this message translates to:
  /// **'Linux loopback only. Enter this backend\'s host-provided session token, not API_SERVER_KEY or a provider key. Reads profiles, sessions and history. Chat requires a separately authenticated ticket connection; legacy local tokens may allow reads only. No launch or credential discovery. This connection and token are not saved; enter them again after relaunch.'**
  String get localServeReadsBody;

  /// No description provided for @localServeEnableChat.
  ///
  /// In en, this message translates to:
  /// **'Enable chat on this session'**
  String get localServeEnableChat;

  /// No description provided for @localServeReconcile.
  ///
  /// In en, this message translates to:
  /// **'Reconcile this session without resending'**
  String get localServeReconcile;

  /// No description provided for @localServeStopRequested.
  ///
  /// In en, this message translates to:
  /// **'Stop requested. Waiting for Hermes to confirm completion; closing the connection does not confirm Stop.'**
  String get localServeStopRequested;

  /// No description provided for @localServeTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes serve session token'**
  String get localServeTokenLabel;

  /// No description provided for @connectionGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect step by step'**
  String get connectionGuideTitle;

  /// No description provided for @connectionGuidePrepare.
  ///
  /// In en, this message translates to:
  /// **'1. Prepare Hermes Agent'**
  String get connectionGuidePrepare;

  /// No description provided for @connectionGuidePrepareBody.
  ///
  /// In en, this message translates to:
  /// **'On the computer running Agent, open the official Hermes dashboard with hermes dashboard. Choose the intended profile, then Channels → API server. Enable the API on loopback for this computer, or ask the host administrator for a trusted HTTPS endpoint. Wing does not install or start Agent.'**
  String get connectionGuidePrepareBody;

  /// No description provided for @connectionGuideAddress.
  ///
  /// In en, this message translates to:
  /// **'2. Enter this profile\'s address'**
  String get connectionGuideAddress;

  /// No description provided for @connectionGuideAddressBody.
  ///
  /// In en, this message translates to:
  /// **'Run hermes gateway status on the Agent host to find its API address. In Wing, omit the final /v1. A shared gateway uses /p/<profile> for a named profile, for example http://127.0.0.1:8642/p/demo. Keep that prefix. On another device, 127.0.0.1 points to that device, not your computer.'**
  String get connectionGuideAddressBody;

  /// No description provided for @connectionGuideToken.
  ///
  /// In en, this message translates to:
  /// **'3. Set up your access token'**
  String get connectionGuideToken;

  /// No description provided for @connectionGuideTokenBody.
  ///
  /// In en, this message translates to:
  /// **'The Agent access token is API_SERVER_KEY, not an OpenAI or Nous provider key. In the official dashboard, select the same profile and open Channels → API server. Set a strong, unique secret in its masked API key field, or obtain the existing credential securely from the administrator. Enter that same secret in Wing\'s masked token field. Do not rotate an existing key without reviewing its other clients. If activation requires a gateway restart, the administrator must arrange it; a shared restart affects other profiles.'**
  String get connectionGuideTokenBody;

  /// No description provided for @connectionGuideGenerateToken.
  ///
  /// In en, this message translates to:
  /// **'Automatic token setup unavailable'**
  String get connectionGuideGenerateToken;

  /// No description provided for @connectionGuideGenerateTokenBody.
  ///
  /// In en, this message translates to:
  /// **'This Agent API has no verified secure operation to generate, register and deliver an access token to Wing. A random value generated here would not grant access. Use the official Agent setup above; Wing never reads secret files or runs host configuration commands.'**
  String get connectionGuideGenerateTokenBody;

  /// No description provided for @connectionGuideBrowser.
  ///
  /// In en, this message translates to:
  /// **'4. Allow this browser'**
  String get connectionGuideBrowser;

  /// No description provided for @connectionGuideBrowserBody.
  ///
  /// In en, this message translates to:
  /// **'On the Agent host, allow the exact Wing origin below in API_SERVER_CORS_ORIGINS. Keep the allowlist narrow. A blocked browser origin cannot be repaired by changing the token. Wing does not change or restart your gateway.'**
  String get connectionGuideBrowserBody;

  /// No description provided for @connectionGuideVerify.
  ///
  /// In en, this message translates to:
  /// **'Check, save, then chat'**
  String get connectionGuideVerify;

  /// No description provided for @connectionGuideVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose Test connection below. Once discovery is verified, choose Add Hermes to connect and save. Open Chat for the saved Agent, select a supported model and send your first message deliberately. Only a reply proves generation; testing does not send a message.'**
  String get connectionGuideVerifyBody;

  /// No description provided for @connectionGuideNext.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get connectionGuideNext;

  /// No description provided for @connectionGuideBack.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get connectionGuideBack;

  /// No description provided for @connectionGuideReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to test'**
  String get connectionGuideReady;

  /// No description provided for @connectionGuideDocs.
  ///
  /// In en, this message translates to:
  /// **'Official Agent setup instructions'**
  String get connectionGuideDocs;

  /// No description provided for @connectionGuideDocsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the instructions. Visit hermes-agent.nousresearch.com/docs/user-guide/features/api-server.'**
  String get connectionGuideDocsFailed;

  /// No description provided for @profileGenerateAvatar.
  ///
  /// In en, this message translates to:
  /// **'Generate avatar'**
  String get profileGenerateAvatar;

  /// No description provided for @profileAvatarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Avatar generation and assignment are unavailable through this Agent API connection. Hermes Desktop has a separate avatar workflow; Wing cannot use it through this API. Your profile is unchanged.'**
  String get profileAvatarUnavailable;

  /// No description provided for @connectionCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get connectionCheckAction;

  /// No description provided for @connectionCheckCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel test'**
  String get connectionCheckCancel;

  /// No description provided for @connectionCheckBoundary.
  ///
  /// In en, this message translates to:
  /// **'Tests authenticated discovery only. It does not save a credential, open Chat, send a message or prove model generation.'**
  String get connectionCheckBoundary;

  /// No description provided for @connectionCheckVerified.
  ///
  /// In en, this message translates to:
  /// **'Discovery verified. Choose Add Hermes to connect and save; send your first message deliberately in Chat.'**
  String get connectionCheckVerified;

  /// No description provided for @connectionCheckUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Discovery verified, but this Agent did not advertise a supported, authorized chat transport. Chat remains unavailable.'**
  String get connectionCheckUnsupported;

  /// No description provided for @connectionCheckDenied.
  ///
  /// In en, this message translates to:
  /// **'Authentication rejected. Use the Agent API token for this exact endpoint and profile, not a provider key. Check access permissions before testing again.'**
  String get connectionCheckDenied;

  /// No description provided for @connectionCheckInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use the full Agent HTTP(S) endpoint, including its profile prefix when required. Do not put credentials, queries or fragments in the URL.'**
  String get connectionCheckInvalid;

  /// No description provided for @connectionCheckIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The response is not a compatible Hermes Agent discovery document. A healthy port or OpenAI chat endpoint alone is not enough.'**
  String get connectionCheckIncompatible;

  /// No description provided for @connectionCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Discovery could not be verified. Check the running Agent, URL and network, then test again deliberately.'**
  String get connectionCheckNetwork;

  /// No description provided for @connectionCheckBrowserNetwork.
  ///
  /// In en, this message translates to:
  /// **'The browser could not verify discovery. Network, certificate, mixed-content or CORS restrictions may hide the cause. This does not prove your token is wrong.'**
  String get connectionCheckBrowserNetwork;

  /// No description provided for @connectionCheckTls.
  ///
  /// In en, this message translates to:
  /// **'The secure connection could not be verified. Fix the certificate or trusted endpoint; do not disable certificate checks.'**
  String get connectionCheckTls;

  /// No description provided for @connectionCheckTimeout.
  ///
  /// In en, this message translates to:
  /// **'Discovery timed out. Check Agent availability and retry deliberately; nothing was saved or sent.'**
  String get connectionCheckTimeout;

  /// No description provided for @connectionBrowserOrigin.
  ///
  /// In en, this message translates to:
  /// **'Wing browser origin: {origin}'**
  String connectionBrowserOrigin(String origin);

  /// No description provided for @connectionBrowserOriginHelp.
  ///
  /// In en, this message translates to:
  /// **'Allow this exact origin in Agent\'s API_SERVER_CORS_ORIGINS. localhost and 127.0.0.1 are different origins. Configuration changes may require an administrator-controlled restart; Wing does not apply them.'**
  String get connectionBrowserOriginHelp;

  /// No description provided for @connectionSetupChecklist.
  ///
  /// In en, this message translates to:
  /// **'Before connecting: start the authenticated Agent API, obtain its exact endpoint and profile-bound API token, then test below. For a shared gateway, a named profile may use /p/<profile>; do not append /v1. Wing cannot read Agent secrets or reveal a Hermes vault entry. A vault fills only its connected browser, not every browser window.'**
  String get connectionSetupChecklist;

  /// No description provided for @chatConnectionSaveUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Connected to Hermes, but saving this connection could not be confirmed. Keep this form open and retry Add Hermes to connect and save again.'**
  String get chatConnectionSaveUnconfirmed;

  /// No description provided for @managedSshGenerateKey.
  ///
  /// In en, this message translates to:
  /// **'Generate SSH key'**
  String get managedSshGenerateKey;

  /// No description provided for @managedSshUseGeneratedKey.
  ///
  /// In en, this message translates to:
  /// **'Use saved Wing key'**
  String get managedSshUseGeneratedKey;

  /// No description provided for @managedSshGenerateKeyConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a key on this device?'**
  String get managedSshGenerateKeyConsentTitle;

  /// No description provided for @managedSshGenerateKeyConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Wing keeps the private key in secure storage on this device. Only its public key is copied. Add that public key to the SSH account on your host. An existing Wing key is reused, never replaced.'**
  String get managedSshGenerateKeyConsentBody;

  /// No description provided for @managedSshGenerateKeyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create or reuse key'**
  String get managedSshGenerateKeyConfirm;

  /// No description provided for @managedSshCopyPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Copy public key'**
  String get managedSshCopyPublicKey;

  /// No description provided for @managedSshPublicKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get managedSshPublicKeyCopied;

  /// No description provided for @managedSshGeneratedKeyStorageFailure.
  ///
  /// In en, this message translates to:
  /// **'Secure key storage is unavailable. No key was selected. Retry or select your own key file.'**
  String get managedSshGeneratedKeyStorageFailure;

  /// No description provided for @managedSshGeneratedKeySelected.
  ///
  /// In en, this message translates to:
  /// **'Wing key selected'**
  String get managedSshGeneratedKeySelected;

  /// No description provided for @managedSshGeneratingKey.
  ///
  /// In en, this message translates to:
  /// **'Creating SSH key…'**
  String get managedSshGeneratingKey;

  /// No description provided for @connectionInformationHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection help'**
  String get connectionInformationHelpTitle;

  /// No description provided for @connectionInformationCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy instructions'**
  String get connectionInformationCopy;

  /// No description provided for @connectionInformationCopied.
  ///
  /// In en, this message translates to:
  /// **'Public instructions copied. No connection values were included.'**
  String get connectionInformationCopied;

  /// No description provided for @connectionInformationCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the instructions. You can select the help text instead.'**
  String get connectionInformationCopyFailed;

  /// No description provided for @connectionInformationClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get connectionInformationClose;

  /// No description provided for @connectionInformationHelpText.
  ///
  /// In en, this message translates to:
  /// **'LOCAL — THIS DEVICE\nLinux: Wing checks ~/.hermes directory metadata. Another Hermes home is not a Project, current working directory or a binding to the running Agent. Discovery does not prove Agent is installed, running, authenticated or model-ready. Configure and start Agent yourself.\nAndroid: localhost and 127.0.0.1 refer to this phone, not your computer. Prepare Agent in Termux using official documentation for current installation steps and limitations. Automatic installation is unavailable in Wing; a fresh install is not qualified by Wing.\n\nSSH — A NATIVE FORWARD\nHost/IP: use the computer\'s reachable hostname or IP provided by its administrator. SSH username: your account on that computer, not the Agent profile. User-run, non-secret Linux examples are whoami (account), hostname -I (candidate addresses) and ss -ltn (listening TCP ports). Addresses may not be reachable from this device. A listening port does not prove it is SSH: verify the actual SSH listener with the administrator.\nSSH port: 22 is a default, not a guarantee. Enter the actual SSH listener port. Review the host-key fingerprint through a trusted administrator before accepting. Authenticate using your SSH password or selected private key, with its passphrase if required. SSH authentication is separate from Agent authentication. For public-key authentication, have the host administrator add only your public key to that SSH account\'s authorized_keys. Never copy, share or install the private key on the host. These commands describe information lookup only, not setup actions.\nAgent port: 8642 is the default API port, but it is configurable. Enter the API listener port on the SSH host, not the SSH port. Wing forwards that listener; an SSH login does not prove Agent readiness.\n\nREMOTE — DIRECT AGENT API\nAgent URL: obtain the full HTTPS API URL from the host administrator, including the configured port or profile path when required. Do not guess an address from network location. A VPN does not replace Agent authentication.\nAgent API token: use the credential supplied separately through Agent-approved configuration. This is not an SSH password, provider key or dashboard token. Type it into the masked Agent token field. Never place secrets in the clipboard, QR codes, URLs or command arguments.\n\nCONNECTING\nConfigure an authenticated Agent API using official Agent documentation. Local uses http://127.0.0.1:8642 by default; that port is configurable on the host. Linux advanced local endpoint controls can select a different configured API endpoint. Android This phone uses the fixed loopback endpoint. Nothing in this help installs, starts, restarts or configures a service. Only an explicit Add Hermes action checks the connection; finishing guidance is not a connected or model-ready state. These copyable instructions contain no current form values or credentials.'**
  String get connectionInformationHelpText;

  /// No description provided for @platformLocalConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect directly to Hermes Agent on this device. Preparing Agent and discovering its home are separate from an authenticated connection.'**
  String get platformLocalConnectBody;

  /// No description provided for @platformLocalTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent API token'**
  String get platformLocalTokenLabel;

  /// No description provided for @platformLocalTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Agent API authentication is required even on loopback. Enter your API token, not a provider key or SSH password.'**
  String get platformLocalTokenHelper;

  /// No description provided for @platformLocalHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes home'**
  String get platformLocalHomeTitle;

  /// No description provided for @platformLocalHomeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Wing checks ~/.hermes directory metadata on this device. Choose another Hermes home if needed. No files are read, and this choice is not saved or sent to Agent. A found directory does not prove an installation, running service, authentication or model readiness, or bind the running Agent to that home.'**
  String get platformLocalHomeExplanation;

  /// No description provided for @platformLocalHomeInspecting.
  ///
  /// In en, this message translates to:
  /// **'Checking default Hermes home…'**
  String get platformLocalHomeInspecting;

  /// No description provided for @platformLocalHomeFound.
  ///
  /// In en, this message translates to:
  /// **'Directory found — discovery only'**
  String get platformLocalHomeFound;

  /// No description provided for @platformLocalHomeMissing.
  ///
  /// In en, this message translates to:
  /// **'Hermes home was not found. Select another directory or prepare Agent separately.'**
  String get platformLocalHomeMissing;

  /// No description provided for @platformLocalHomeNotDirectory.
  ///
  /// In en, this message translates to:
  /// **'The selected location is not a directory.'**
  String get platformLocalHomeNotDirectory;

  /// No description provided for @platformLocalHomeUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not inspect this directory. Check access or choose another Hermes home.'**
  String get platformLocalHomeUnreadable;

  /// No description provided for @platformLocalHomeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Directory inspection is unavailable on this platform.'**
  String get platformLocalHomeUnsupported;

  /// No description provided for @platformLocalChooseHome.
  ///
  /// In en, this message translates to:
  /// **'Choose another Hermes home'**
  String get platformLocalChooseHome;

  /// No description provided for @platformLocalAdvancedEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Advanced local endpoint'**
  String get platformLocalAdvancedEndpoint;

  /// No description provided for @platformLocalPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get platformLocalPhoneTitle;

  /// No description provided for @platformLocalPhoneBoundary.
  ///
  /// In en, this message translates to:
  /// **'Prepare Hermes Agent in Termux yourself, then connect directly. Wing cannot inspect Termux files and does not install, configure, start or restart Agent. Loopback still requires authentication.'**
  String get platformLocalPhoneBoundary;

  /// No description provided for @platformLocalPackageWarning.
  ///
  /// In en, this message translates to:
  /// **'Automatic installation is unavailable in Wing. Follow the official Agent Termux documentation for current installation steps and limitations. Fresh installation and persistent background operation are not qualified by Wing. Debian/proot is a separate, unqualified setup path.'**
  String get platformLocalPackageWarning;

  /// No description provided for @platformLocalPrepareTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Termux and Agent'**
  String get platformLocalPrepareTitle;

  /// No description provided for @platformLocalPrepareBody.
  ///
  /// In en, this message translates to:
  /// **'Install or open Termux using its official guide. For a fresh Agent installation, read the package warning and current official documentation first. If Agent is already installed, check hermes --version and hermes doctor in Termux before continuing.'**
  String get platformLocalPrepareBody;

  /// No description provided for @platformLocalTermuxDocs.
  ///
  /// In en, this message translates to:
  /// **'Official Termux installation guide'**
  String get platformLocalTermuxDocs;

  /// No description provided for @platformLocalAgentDocs.
  ///
  /// In en, this message translates to:
  /// **'Official Agent Termux documentation'**
  String get platformLocalAgentDocs;

  /// No description provided for @platformLocalExistingAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent is installed — configure it'**
  String get platformLocalExistingAgent;

  /// No description provided for @platformLocalSkipGuide.
  ///
  /// In en, this message translates to:
  /// **'Agent already running — skip guide'**
  String get platformLocalSkipGuide;

  /// No description provided for @platformLocalConfigureTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Configure and start Agent'**
  String get platformLocalConfigureTitle;

  /// No description provided for @platformLocalConfigureBody.
  ///
  /// In en, this message translates to:
  /// **'In Termux, run hermes setup to configure your provider and model. Follow Agent\'s API documentation to enable API_SERVER_ENABLED=true, set a strong API_SERVER_KEY in Agent-owned configuration, and use API_SERVER_HOST=127.0.0.1 and API_SERVER_PORT=8642. Never put credentials in command arguments or the clipboard. Run hermes gateway in the foreground and keep Termux open. Android may suspend or stop it. Continuing only records your choice; it does not verify readiness.'**
  String get platformLocalConfigureBody;

  /// No description provided for @platformLocalApiDocs.
  ///
  /// In en, this message translates to:
  /// **'Official authenticated API setup'**
  String get platformLocalApiDocs;

  /// No description provided for @platformLocalStartedAgent.
  ///
  /// In en, this message translates to:
  /// **'I started Agent — continue to connection'**
  String get platformLocalStartedAgent;

  /// No description provided for @platformLocalAuthenticateTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Connect to Agent'**
  String get platformLocalAuthenticateTitle;

  /// No description provided for @platformLocalAuthenticateBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to http://127.0.0.1:8642 on this phone. Type the Agent API token into the masked field below, not a provider key or dashboard token. Connection is checked only when you choose Add Hermes; guide completion is not a connected state.'**
  String get platformLocalAuthenticateBody;

  /// No description provided for @platformLocalGuideBack.
  ///
  /// In en, this message translates to:
  /// **'Back to guidance'**
  String get platformLocalGuideBack;

  /// No description provided for @platformLocalDocumentationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the official documentation. Try again when a browser is available.'**
  String get platformLocalDocumentationFailed;

  /// No description provided for @platformLocalBrowserExplanation.
  ///
  /// In en, this message translates to:
  /// **'This platform cannot inspect the Agent host\'s Hermes home. Use the direct authenticated Agent API below. In a full browser, loopback refers to the browser\'s device; browser transport rules still apply.'**
  String get platformLocalBrowserExplanation;

  /// No description provided for @welcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'HERMES WING'**
  String get welcomeEyebrow;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hermes Wing'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your self-improving AI assistant. Connect to Hermes Agent on your machine or a trusted remote host.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to a running local Hermes Agent. Nothing is installed automatically.'**
  String get welcomeLocalHint;

  /// No description provided for @welcomeOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get welcomeOr;

  /// No description provided for @welcomeSsh.
  ///
  /// In en, this message translates to:
  /// **'Connect via SSH'**
  String get welcomeSsh;

  /// No description provided for @managedSshInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Use a bounded access token without spaces or control characters.'**
  String get managedSshInvalidToken;

  /// No description provided for @managedSshPrivateKeyChoice.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get managedSshPrivateKeyChoice;

  /// No description provided for @managedSshPasswordChoice.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get managedSshPasswordChoice;

  /// No description provided for @managedSshSelectKey.
  ///
  /// In en, this message translates to:
  /// **'Select private key'**
  String get managedSshSelectKey;

  /// No description provided for @managedSshKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a private key for this connection attempt.'**
  String get managedSshKeyRequired;

  /// No description provided for @managedSshPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Private-key passphrase'**
  String get managedSshPassphrase;

  /// No description provided for @managedSshPassphraseRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a passphrase of at most 4096 characters without null characters.'**
  String get managedSshPassphraseRequired;

  /// No description provided for @managedSshUnlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock this private key. Check its passphrase or select another key.'**
  String get managedSshUnlockFailed;

  /// No description provided for @managedSshKeyUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected private key. Select it again.'**
  String get managedSshKeyUnreadable;

  /// No description provided for @managedSshKeyTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The selected private key exceeds 64 KiB.'**
  String get managedSshKeyTooLarge;

  /// No description provided for @managedSshKeyUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This private-key format is not supported. Select an OpenSSH, RSA or EC private key.'**
  String get managedSshKeyUnsupportedFormat;

  /// No description provided for @managedSshKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid supported SSH private key.'**
  String get managedSshKeyInvalid;

  /// No description provided for @managedSshSelectedKey.
  ///
  /// In en, this message translates to:
  /// **'Selected private key'**
  String get managedSshSelectedKey;

  /// No description provided for @managedSshAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'SSH authentication was rejected. Check your username and authentication choice, then retry.'**
  String get managedSshAuthenticationFailed;

  /// No description provided for @managedSshHostLabel.
  ///
  /// In en, this message translates to:
  /// **'SSH host'**
  String get managedSshHostLabel;

  /// No description provided for @managedSshPortLabel.
  ///
  /// In en, this message translates to:
  /// **'SSH port'**
  String get managedSshPortLabel;

  /// No description provided for @managedSshUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get managedSshUsernameLabel;

  /// No description provided for @managedSshPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'SSH password'**
  String get managedSshPasswordLabel;

  /// No description provided for @managedSshAgentPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent port'**
  String get managedSshAgentPortLabel;

  /// No description provided for @managedSshAgentTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent access token (optional)'**
  String get managedSshAgentTokenLabel;

  /// No description provided for @managedSshConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect via SSH'**
  String get managedSshConnectAction;

  /// No description provided for @managedSshConnectingAction.
  ///
  /// In en, this message translates to:
  /// **'Connecting via SSH…'**
  String get managedSshConnectingAction;

  /// No description provided for @managedSshInvalidHost.
  ///
  /// In en, this message translates to:
  /// **'Enter a host name or IP address, not a URL or command.'**
  String get managedSshInvalidHost;

  /// No description provided for @managedSshInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Enter a port from 1 to 65535.'**
  String get managedSshInvalidPort;

  /// No description provided for @managedSshUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your SSH username.'**
  String get managedSshUsernameRequired;

  /// No description provided for @managedSshPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your SSH password.'**
  String get managedSshPasswordRequired;

  /// No description provided for @managedSshHostKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify SSH host'**
  String get managedSshHostKeyTitle;

  /// No description provided for @managedSshHostKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Compare this fingerprint with the host\'s SSH key before trusting it. Wing will remember this host and SSH port securely and block changed keys. Cancel if you cannot verify it.'**
  String get managedSshHostKeyBody;

  /// No description provided for @managedSshHostKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'The SSH host key differs from the remembered key. Connection blocked. Verify the change with the host administrator; Wing cannot replace a remembered key here.'**
  String get managedSshHostKeyChanged;

  /// No description provided for @managedSshHostTrustUnavailable.
  ///
  /// In en, this message translates to:
  /// **'SSH host trust could not be read or saved securely. Connection blocked. Restore secure storage access before trying again.'**
  String get managedSshHostTrustUnavailable;

  /// No description provided for @managedSshTrustAction.
  ///
  /// In en, this message translates to:
  /// **'Trust and remember host'**
  String get managedSshTrustAction;

  /// No description provided for @managedSshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not establish the SSH connection. Check the host and authentication, then retry.'**
  String get managedSshFailed;

  /// No description provided for @managedSshUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Managed SSH is not available in this browser. Use Wing on Android or desktop.'**
  String get managedSshUnsupported;

  /// No description provided for @welcomeRemote.
  ///
  /// In en, this message translates to:
  /// **'Connect to Remote Hermes'**
  String get welcomeRemote;

  /// No description provided for @welcomeStorageRetry.
  ///
  /// In en, this message translates to:
  /// **'Saved connections could not be read. Retry'**
  String get welcomeStorageRetry;

  /// No description provided for @profilesSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search profiles'**
  String get profilesSearchLabel;

  /// No description provided for @chatProfileSearch.
  ///
  /// In en, this message translates to:
  /// **'Search profiles by name, ID or model'**
  String get chatProfileSearch;

  /// No description provided for @chatProfileManage.
  ///
  /// In en, this message translates to:
  /// **'Manage profiles'**
  String get chatProfileManage;

  /// No description provided for @chatProfileHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Keyboard selection'**
  String get chatProfileHighlighted;

  /// No description provided for @profilesSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear profile search'**
  String get profilesSearchClear;

  /// No description provided for @profilesSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'Search this loaded inventory by profile ID, name, description or model. Search does not change the active chat.'**
  String get profilesSearchHelp;

  /// No description provided for @profilesSearchNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching profiles'**
  String get profilesSearchNoMatchesTitle;

  /// No description provided for @profilesSearchNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try another profile ID, name, description or model, or clear the search.'**
  String get profilesSearchNoMatchesBody;

  /// No description provided for @chatSessionRestorationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Restoring your conversation'**
  String get chatSessionRestorationPendingTitle;

  /// No description provided for @chatSessionRestorationPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Opening your remembered conversation. Sending and New Chat are paused so nothing goes to another session.'**
  String get chatSessionRestorationPendingBody;

  /// No description provided for @chatSessionRestorationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation not restored'**
  String get chatSessionRestorationFailedTitle;

  /// No description provided for @chatSessionRestorationUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'This Agent does not support restoring the remembered conversation directly. Retry after its capabilities change, or choose a session.'**
  String get chatSessionRestorationUnsupportedBody;

  /// No description provided for @chatSessionRestorationAuthenticationBody.
  ///
  /// In en, this message translates to:
  /// **'The Agent did not authorize access to the remembered conversation. Check this connection’s access, then retry or choose a session.'**
  String get chatSessionRestorationAuthenticationBody;

  /// No description provided for @chatSessionRestorationUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The remembered conversation is unavailable. It has not been replaced. Retry, or choose a session.'**
  String get chatSessionRestorationUnavailableBody;

  /// No description provided for @chatSessionRestorationTransientBody.
  ///
  /// In en, this message translates to:
  /// **'The remembered conversation could not be reached. It has not been replaced. Retry, or choose a session.'**
  String get chatSessionRestorationTransientBody;

  /// No description provided for @chatSessionRestorationIncompatibleBody.
  ///
  /// In en, this message translates to:
  /// **'The Agent response could not confirm the remembered conversation. It has not been replaced. Retry, or choose a session.'**
  String get chatSessionRestorationIncompatibleBody;

  /// No description provided for @chatSessionRestorationRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatSessionRestorationRetry;

  /// No description provided for @chatSessionRestorationChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose session'**
  String get chatSessionRestorationChoose;

  /// No description provided for @chatSessionRestorationProfileRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Retry to load this profile’s sessions before choosing a conversation.'**
  String get chatSessionRestorationProfileRequiredBody;

  /// No description provided for @profileCatalogLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading providers and models from Hermes Agent…'**
  String get profileCatalogLoading;

  /// No description provided for @profileCatalogUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Agent catalog could not be loaded. Retry, or enter a provider and model manually.'**
  String get profileCatalogUnavailable;

  /// No description provided for @profileCatalogRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry catalog'**
  String get profileCatalogRetry;

  /// No description provided for @transcriptLargeMessageScroll.
  ///
  /// In en, this message translates to:
  /// **'Large message. Scroll to read all content.'**
  String get transcriptLargeMessageScroll;

  /// No description provided for @chatAttachmentDraftEvicted.
  ///
  /// In en, this message translates to:
  /// **'The attachment was released to save memory. Attach it again before sending.'**
  String get chatAttachmentDraftEvicted;

  /// No description provided for @chatTranscriptLatestAction.
  ///
  /// In en, this message translates to:
  /// **'Latest activity'**
  String get chatTranscriptLatestAction;

  /// No description provided for @chatTranscriptRevealEarlier.
  ///
  /// In en, this message translates to:
  /// **'Show up to 100 earlier loaded turns ({remaining} remaining)'**
  String chatTranscriptRevealEarlier(int remaining);

  /// No description provided for @chatTranscriptContinuedTools.
  ///
  /// In en, this message translates to:
  /// **'{title} (continued)'**
  String chatTranscriptContinuedTools(String title);

  /// No description provided for @chatVoiceMuteOutputAction.
  ///
  /// In en, this message translates to:
  /// **'Mute speech'**
  String get chatVoiceMuteOutputAction;

  /// No description provided for @chatVoiceUnmuteOutputAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute speech'**
  String get chatVoiceUnmuteOutputAction;

  /// No description provided for @chatVoicePauseMicrophoneAction.
  ///
  /// In en, this message translates to:
  /// **'End hands-free listening'**
  String get chatVoicePauseMicrophoneAction;

  /// No description provided for @chatVoiceEndAction.
  ///
  /// In en, this message translates to:
  /// **'End voice session'**
  String get chatVoiceEndAction;

  /// No description provided for @chatVoiceStopOutputAction.
  ///
  /// In en, this message translates to:
  /// **'Stop reply'**
  String get chatVoiceStopOutputAction;

  /// No description provided for @chatVoiceWaitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reply'**
  String get chatVoiceWaitingLabel;

  /// No description provided for @chatVoiceDictateAction.
  ///
  /// In en, this message translates to:
  /// **'Dictate a draft'**
  String get chatVoiceDictateAction;

  /// No description provided for @chatVoiceCancelDraftAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel draft dictation'**
  String get chatVoiceCancelDraftAction;

  /// No description provided for @chatVoiceDictateHint.
  ///
  /// In en, this message translates to:
  /// **'Review the text before sending'**
  String get chatVoiceDictateHint;

  /// No description provided for @chatVoicePausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice paused'**
  String get chatVoicePausedTitle;

  /// No description provided for @chatVoiceResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume hands-free'**
  String get chatVoiceResumeAction;

  /// No description provided for @chatVoiceInterruptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening for interruption'**
  String get chatVoiceInterruptionLabel;

  /// No description provided for @chatVoiceOutputLabel.
  ///
  /// In en, this message translates to:
  /// **'Playing assistant reply'**
  String get chatVoiceOutputLabel;

  /// No description provided for @profileActiveChat.
  ///
  /// In en, this message translates to:
  /// **'Active chat'**
  String get profileActiveChat;

  /// No description provided for @profileFreshSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider and model for this new profile.'**
  String get profileFreshSetupHint;

  /// No description provided for @profileCloneSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Copies this profile’s configuration. Leave provider and model blank to inherit them.'**
  String get profileCloneSetupHint;

  /// No description provided for @chatHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host: {host}'**
  String chatHostLabel(String host);

  /// No description provided for @chatNamedComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message {profile}…'**
  String chatNamedComposerHint(String profile);

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing'**
  String get appTitle;

  /// No description provided for @hermesDestination.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get hermesDestination;

  /// No description provided for @agentsDestination.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
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
  /// **'Profiles'**
  String get agentsTitle;

  /// No description provided for @agentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile to chat, or create one for a different task.'**
  String get agentsSubtitle;

  /// No description provided for @newAgent.
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get newAgent;

  /// No description provided for @agentsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profiles'**
  String get agentsLoading;

  /// No description provided for @agentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No profiles available'**
  String get agentsEmptyTitle;

  /// No description provided for @agentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with profile access to view Hermes profiles.'**
  String get agentsEmptyBody;

  /// No description provided for @agentsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles unavailable'**
  String get agentsUnavailableTitle;

  /// No description provided for @agentsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Update Hermes Agent and reconnect this gateway with profile permissions.'**
  String get agentsUnavailableBody;

  /// No description provided for @agentsConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Profiles could not be loaded from Hermes.'**
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

  /// No description provided for @agentGatewayUnknown.
  ///
  /// In en, this message translates to:
  /// **'Gateway state unknown'**
  String get agentGatewayUnknown;

  /// No description provided for @profileEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get profileEnrolled;

  /// No description provided for @profileNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Not enrolled'**
  String get profileNotEnrolled;

  /// No description provided for @agentNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get agentNoModel;

  /// No description provided for @agentsLocalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load local profiles.'**
  String get agentsLocalLoadError;

  /// No description provided for @agentsGatewayConnectError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to this gateway.'**
  String get agentsGatewayConnectError;

  /// No description provided for @profileStableNameHint.
  ///
  /// In en, this message translates to:
  /// **'Use 1–64 lowercase letters, numbers, _ or -.'**
  String get profileStableNameHint;

  /// No description provided for @chatWithAgent.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatWithAgent;

  /// No description provided for @profileChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Management only — this Hermes endpoint does not advertise profile chat context.'**
  String get profileChatUnavailable;

  /// No description provided for @profileBrowseFoldersAction.
  ///
  /// In en, this message translates to:
  /// **'Browse folders'**
  String get profileBrowseFoldersAction;

  /// No description provided for @chatWithNamedAgent.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWithNamedAgent(String name);

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

  /// No description provided for @editNamedAgent.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editNamedAgent(String name);

  /// No description provided for @createAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get createAgentTitle;

  /// No description provided for @agentDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get agentDisplayName;

  /// No description provided for @agentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a profile name.'**
  String get agentNameRequired;

  /// No description provided for @profileDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get profileDescriptionLabel;

  /// No description provided for @profileProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get profileProviderLabel;

  /// No description provided for @profileProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a provider.'**
  String get profileProviderRequired;

  /// No description provided for @profileModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get profileModelLabel;

  /// No description provided for @profileModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a model.'**
  String get profileModelRequired;

  /// No description provided for @profileCredentialLabel.
  ///
  /// In en, this message translates to:
  /// **'New provider credential'**
  String get profileCredentialLabel;

  /// No description provided for @profileCredentialHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. This value is write-only and is never shown again.'**
  String get profileCredentialHint;

  /// No description provided for @profileReadinessNotice.
  ///
  /// In en, this message translates to:
  /// **'Saving sends one ‘Hi’ through Hermes to verify that this provider and model can answer.'**
  String get profileReadinessNotice;

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

  /// No description provided for @openChatAction.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChatAction;

  /// No description provided for @gatewayConnectionRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Choose another saved gateway above, or return to Chat to reconnect.'**
  String get gatewayConnectionRecoveryBody;

  /// No description provided for @chatSavedEndpointsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading saved Hermes gateways'**
  String get chatSavedEndpointsLoading;

  /// No description provided for @chatSavedEndpointEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit saved Agent connection'**
  String get chatSavedEndpointEdit;

  /// No description provided for @chatSavedEndpointEditBody.
  ///
  /// In en, this message translates to:
  /// **'Edit this saved connection only. Saving does not connect or change the active conversation. A changed Agent URL requires its own Agent credential.'**
  String get chatSavedEndpointEditBody;

  /// No description provided for @chatSavedEndpointReplacementKey.
  ///
  /// In en, this message translates to:
  /// **'Replacement Agent credential'**
  String get chatSavedEndpointReplacementKey;

  /// No description provided for @chatSavedEndpointKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the saved credential only while the URL is unchanged. A changed URL needs its own credential. Saved credentials are never shown here.'**
  String get chatSavedEndpointKeyHelp;

  /// No description provided for @chatSavedEndpointRemoveKey.
  ///
  /// In en, this message translates to:
  /// **'Remove saved Agent credential'**
  String get chatSavedEndpointRemoveKey;

  /// No description provided for @chatSavedEndpointTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get chatSavedEndpointTest;

  /// No description provided for @chatSavedEndpointCancelTest.
  ///
  /// In en, this message translates to:
  /// **'Cancel test'**
  String get chatSavedEndpointCancelTest;

  /// No description provided for @chatSavedEndpointTestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Test cancelled. No connection was saved or activated.'**
  String get chatSavedEndpointTestCancelled;

  /// No description provided for @chatSavedEndpointTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supported Agent discovery responded. No connection was saved or activated. This does not verify chat or inference permissions.'**
  String get chatSavedEndpointTestSuccess;

  /// No description provided for @chatSavedEndpointTestDenied.
  ///
  /// In en, this message translates to:
  /// **'Agent discovery denied this credential. Check the draft and explicitly test again.'**
  String get chatSavedEndpointTestDenied;

  /// No description provided for @chatSavedEndpointTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Agent discovery could not be verified. Check the URL, network and credential, then explicitly test again.'**
  String get chatSavedEndpointTestFailed;

  /// No description provided for @chatSavedEndpointStale.
  ///
  /// In en, this message translates to:
  /// **'The connection owner or draft changed. Close this editor and open the saved connection again.'**
  String get chatSavedEndpointStale;

  /// No description provided for @chatSavedEndpointSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved connection updated. The active conversation is unchanged.'**
  String get chatSavedEndpointSaved;

  /// No description provided for @chatSavedEndpointSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this connection. Check the URL and secure storage, then explicitly save again. Another saved host cannot be replaced by this edit.'**
  String get chatSavedEndpointSaveFailed;

  /// No description provided for @chatSavedEndpointsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved gateways unavailable'**
  String get chatSavedEndpointsLoadFailedTitle;

  /// No description provided for @chatSavedEndpointsLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing could not read saved gateways from secure storage. You can still enter connection details manually.'**
  String get chatSavedEndpointsLoadFailedBody;

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

  /// No description provided for @personaLabel.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get personaLabel;

  /// No description provided for @personaLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the authoritative persona'**
  String get personaLoading;

  /// No description provided for @personaHint.
  ///
  /// In en, this message translates to:
  /// **'Describe this profile’s role, voice, and working style.'**
  String get personaHint;

  /// No description provided for @deleteAgent.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get deleteAgent;

  /// No description provided for @deleteNamedAgent.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteNamedAgent(String name);

  /// No description provided for @deleteAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteAgentTitle(String name);

  /// No description provided for @deleteAgentBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the profile from Hermes. Type its display name to confirm.'**
  String get deleteAgentBody;

  /// No description provided for @deleteConfirmationLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get deleteConfirmationLabel;

  /// No description provided for @defaultAgentCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'The default profile cannot be deleted.'**
  String get defaultAgentCannotDelete;

  /// No description provided for @profileOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Hermes could not complete that profile change.'**
  String get profileOperationFailed;

  /// No description provided for @profileRevisionConflict.
  ///
  /// In en, this message translates to:
  /// **'This profile changed elsewhere. The latest version has been loaded; review it before trying again.'**
  String get profileRevisionConflict;

  /// No description provided for @switchAgent.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get switchAgent;

  /// No description provided for @switchAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get switchAgentTitle;

  /// No description provided for @switchAgentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch profile: {message}'**
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

  /// No description provided for @toolsRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh inventory'**
  String get toolsRefreshAction;

  /// No description provided for @toolsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Tool inventory could not be refreshed.'**
  String get toolsRefreshFailed;

  /// No description provided for @toolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skills and toolsets available on this gateway.'**
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

  /// No description provided for @shellProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get shellProfileLabel;

  /// No description provided for @shellModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get shellModelLabel;

  /// No description provided for @shellInventoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get shellInventoryLabel;

  /// No description provided for @shellConnectedHost.
  ///
  /// In en, this message translates to:
  /// **'Connected · {host}'**
  String shellConnectedHost(String host);

  /// No description provided for @shellDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get shellDisconnected;

  /// No description provided for @shellWorkflowNavigation.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get shellWorkflowNavigation;

  /// No description provided for @shellUtilityNavigation.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get shellUtilityNavigation;

  /// No description provided for @shellNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get shellNotLoaded;

  /// No description provided for @shellUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get shellUnavailable;

  /// No description provided for @shellInventorySummary.
  ///
  /// In en, this message translates to:
  /// **'{tools, plural, =1{1 tool} other{{tools} tools}} · {skills, plural, =1{1 skill} other{{skills} skills}}'**
  String shellInventorySummary(int tools, int skills);

  /// No description provided for @selectGatewayHint.
  ///
  /// In en, this message translates to:
  /// **'Select gateway'**
  String get selectGatewayHint;

  /// No description provided for @gatewaySelectPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a gateway'**
  String get gatewaySelectPromptTitle;

  /// No description provided for @toolsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools unavailable'**
  String get toolsUnavailableTitle;

  /// No description provided for @schedulesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedules unavailable'**
  String get schedulesUnavailableTitle;

  /// No description provided for @gatewayStatusUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway status unavailable'**
  String get gatewayStatusUnavailableTitle;

  /// No description provided for @agentsConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Open a saved gateway chat before managing its profiles.'**
  String get agentsConnectionRequiredBody;

  /// No description provided for @providersConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Open a saved gateway chat before managing providers and models.'**
  String get providersConnectionRequiredBody;

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

  /// No description provided for @gatewayDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from this gateway?'**
  String get gatewayDisconnectTitle;

  /// No description provided for @gatewayDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing will close this connection. The saved gateway and API key stay on this device so you can reconnect later.'**
  String get gatewayDisconnectBody;

  /// No description provided for @gatewayDisconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not disconnect from this gateway.'**
  String get gatewayDisconnectFailed;

  /// No description provided for @connectionProfileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 profile} other{{count} profiles}}'**
  String connectionProfileCount(int count);

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

  /// No description provided for @toolsetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Toolsets'**
  String get toolsetsTitle;

  /// No description provided for @searchToolsetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search toolsets and resolved tools'**
  String get searchToolsetsLabel;

  /// No description provided for @clearToolsetsSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear toolsets search'**
  String get clearToolsetsSearch;

  /// No description provided for @noToolsetsMatchBody.
  ///
  /// In en, this message translates to:
  /// **'No toolsets match this search.'**
  String get noToolsetsMatchBody;

  /// No description provided for @toolsetsCatalogEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No toolsets were reported.'**
  String get toolsetsCatalogEmptyBody;

  /// No description provided for @toolsetEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get toolsetEnabled;

  /// No description provided for @toolsetDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get toolsetDisabled;

  /// No description provided for @toolsetConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get toolsetConfigured;

  /// No description provided for @toolsetNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get toolsetNotConfigured;

  /// No description provided for @toolsetResolvedToolsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 resolved tool} other{{count} resolved tools}}'**
  String toolsetResolvedToolsCount(int count);

  /// No description provided for @toolsetResolvedToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolved tools'**
  String get toolsetResolvedToolsTitle;

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

  /// No description provided for @clearInstalledSkillsSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear installed skills search'**
  String get clearInstalledSkillsSearch;

  /// No description provided for @noSkillsMatchBody.
  ///
  /// In en, this message translates to:
  /// **'No installed skills match this search.'**
  String get noSkillsMatchBody;

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
  /// **'Scheduled work for this profile.'**
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

  /// No description provided for @schedulesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No schedules yet'**
  String get schedulesEmptyTitle;

  /// No description provided for @schedulesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No scheduled jobs were reported for this profile.'**
  String get schedulesEmptyBody;

  /// No description provided for @schedulesReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Read-only schedule inventory. Manage scheduled work on the host.'**
  String get schedulesReadOnlyNote;

  /// No description provided for @schedulesRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh schedules'**
  String get schedulesRefreshTooltip;

  /// No description provided for @schedulesRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing scheduled jobs'**
  String get schedulesRefreshing;

  /// No description provided for @schedulesSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search schedules'**
  String get schedulesSearchLabel;

  /// No description provided for @schedulesFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Show schedules'**
  String get schedulesFilterLabel;

  /// No description provided for @schedulesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get schedulesFilterAll;

  /// No description provided for @schedulesClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get schedulesClearFilters;

  /// No description provided for @schedulesNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching schedules'**
  String get schedulesNoMatchesTitle;

  /// No description provided for @schedulesNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try another name, job ID or schedule, or clear the filters.'**
  String get schedulesNoMatchesBody;

  /// No description provided for @scheduleIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Job ID'**
  String get scheduleIdLabel;

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

  /// No description provided for @scheduleError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get scheduleError;

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
  /// **'Connections'**
  String get gatewayDestination;

  /// No description provided for @gatewayStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get gatewayStatusTitle;

  /// No description provided for @gatewayChatDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Chat disconnected'**
  String get gatewayChatDisconnected;

  /// No description provided for @gatewayChatDisconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Chat could not disconnect. Try again.'**
  String get gatewayChatDisconnectFailed;

  /// No description provided for @gatewayChatConnected.
  ///
  /// In en, this message translates to:
  /// **'Chat connected'**
  String get gatewayChatConnected;

  /// No description provided for @gatewayChatConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect chat'**
  String get gatewayChatConnectAction;

  /// No description provided for @gatewaySavedConnectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Connect chat to use this saved Agent connection. Disconnecting keeps it saved and does not stop Hermes Agent on the host.'**
  String get gatewaySavedConnectionHelp;

  /// No description provided for @gatewayStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Host connection and service health.'**
  String get gatewayStatusSubtitle;

  /// No description provided for @gatewayStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'View status from the selected gateway.'**
  String get gatewayStatusHelp;

  /// No description provided for @gatewayStatusConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Select a saved Agent connection and choose Connect chat to load Agent status.'**
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

  /// No description provided for @gatewayStatusBasicOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Connected. Showing basic health because this gateway does not advertise detailed status.'**
  String get gatewayStatusBasicOnlyBody;

  /// No description provided for @gatewayStatusDetailedFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Connected. Basic health is available, but detailed status could not be loaded.'**
  String get gatewayStatusDetailedFallbackBody;

  /// No description provided for @gatewayStatusReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Read-only gateway status. Manage services, logs, and messaging platforms on the host.'**
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
  /// **'Active profiles'**
  String get gatewayActiveAgentsLabel;

  /// No description provided for @gatewayWorkStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Work state'**
  String get gatewayWorkStateLabel;

  /// No description provided for @gatewayBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get gatewayBusy;

  /// No description provided for @gatewayIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get gatewayIdle;

  /// No description provided for @gatewayDrainableLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe to drain'**
  String get gatewayDrainableLabel;

  /// No description provided for @gatewayYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get gatewayYes;

  /// No description provided for @gatewayNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get gatewayNo;

  /// No description provided for @gatewayUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get gatewayUpdatedLabel;

  /// No description provided for @gatewayProcessIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Process ID'**
  String get gatewayProcessIdLabel;

  /// No description provided for @gatewayExitReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit reason'**
  String get gatewayExitReasonLabel;

  /// No description provided for @gatewayRuntimeReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime readiness'**
  String get gatewayRuntimeReadinessTitle;

  /// No description provided for @gatewayMessagingPlatformsTitle.
  ///
  /// In en, this message translates to:
  /// **'Messaging platforms'**
  String get gatewayMessagingPlatformsTitle;

  /// No description provided for @gatewayStateDatabaseLabel.
  ///
  /// In en, this message translates to:
  /// **'State database'**
  String get gatewayStateDatabaseLabel;

  /// No description provided for @gatewayConfigurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get gatewayConfigurationLabel;

  /// No description provided for @gatewayModelReadinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get gatewayModelReadinessLabel;

  /// No description provided for @gatewayDiskReadinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get gatewayDiskReadinessLabel;

  /// No description provided for @gatewayRuntimeReadinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway runtime'**
  String get gatewayRuntimeReadinessLabel;

  /// No description provided for @gatewayBackgroundQueuesLabel.
  ///
  /// In en, this message translates to:
  /// **'Background queues'**
  String get gatewayBackgroundQueuesLabel;

  /// No description provided for @gatewayReadinessDiskUsage.
  ///
  /// In en, this message translates to:
  /// **'{usedPercent}% used'**
  String gatewayReadinessDiskUsage(String usedPercent);

  /// No description provided for @gatewayReadinessPlatformCounts.
  ///
  /// In en, this message translates to:
  /// **'{connected} of {configured} connected'**
  String gatewayReadinessPlatformCounts(int connected, int configured);

  /// No description provided for @gatewayReadinessQueueCounts.
  ///
  /// In en, this message translates to:
  /// **'{activeRuns} API runs · {completions} completions · {delegations} delegations'**
  String gatewayReadinessQueueCounts(
    int activeRuns,
    int completions,
    int delegations,
  );

  /// No description provided for @providersTitle.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providersTitle;

  /// No description provided for @providersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a model and manage provider access.'**
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

  /// No description provided for @providersSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search providers'**
  String get providersSearchLabel;

  /// No description provided for @providersSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear provider search'**
  String get providersSearchClear;

  /// No description provided for @providersSearchNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching providers'**
  String get providersSearchNoMatchesTitle;

  /// No description provided for @providersSearchNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try another provider name or slug, or clear the search.'**
  String get providersSearchNoMatchesBody;

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

  /// No description provided for @providersConfiguredSection.
  ///
  /// In en, this message translates to:
  /// **'Configured providers'**
  String get providersConfiguredSection;

  /// No description provided for @providersAvailableSection.
  ///
  /// In en, this message translates to:
  /// **'Available providers'**
  String get providersAvailableSection;

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

  /// No description provided for @providerAuthApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get providerAuthApiKey;

  /// No description provided for @providerAuthOAuth.
  ///
  /// In en, this message translates to:
  /// **'OAuth sign-in'**
  String get providerAuthOAuth;

  /// No description provided for @providerAuthOther.
  ///
  /// In en, this message translates to:
  /// **'Provider-managed authentication'**
  String get providerAuthOther;

  /// No description provided for @providerOAuthHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in on the Hermes host. This Agent does not advertise remote OAuth setup.'**
  String get providerOAuthHostRequired;

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

  /// No description provided for @runtimeModelPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary runtime model'**
  String get runtimeModelPrimary;

  /// No description provided for @runtimeModelRouteAlias.
  ///
  /// In en, this message translates to:
  /// **'Route alias'**
  String get runtimeModelRouteAlias;

  /// No description provided for @runtimeModelRoutesTo.
  ///
  /// In en, this message translates to:
  /// **'Routes to {model}'**
  String runtimeModelRoutesTo(String model);

  /// No description provided for @runtimeModelParent.
  ///
  /// In en, this message translates to:
  /// **'Parent {model}'**
  String runtimeModelParent(String model);

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

  /// No description provided for @sessionModelPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Use a model for this session'**
  String get sessionModelPickerTitle;

  /// No description provided for @sessionModelPickerDescription.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent will keep this model selection scoped to the current session.'**
  String get sessionModelPickerDescription;

  /// No description provided for @sessionModelLockAction.
  ///
  /// In en, this message translates to:
  /// **'Use for session'**
  String get sessionModelLockAction;

  /// No description provided for @sessionModelLockFailed.
  ///
  /// In en, this message translates to:
  /// **'Hermes could not confirm this session model.'**
  String get sessionModelLockFailed;

  /// No description provided for @sessionModelSearch.
  ///
  /// In en, this message translates to:
  /// **'Search models or providers'**
  String get sessionModelSearch;

  /// No description provided for @sessionModelClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear model search'**
  String get sessionModelClearSearch;

  /// No description provided for @sessionModelAllProviders.
  ///
  /// In en, this message translates to:
  /// **'All selectable providers'**
  String get sessionModelAllProviders;

  /// No description provided for @sessionModelResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get sessionModelResetFilters;

  /// No description provided for @sessionModelNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching selectable models. Clear the search or reset filters.'**
  String get sessionModelNoResults;

  /// No description provided for @sessionModelCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No selectable session models are available from Hermes Agent.'**
  String get sessionModelCatalogEmpty;

  /// No description provided for @sessionModelSelectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected model is no longer available. Choose a model from the current catalog.'**
  String get sessionModelSelectionUnavailable;

  /// No description provided for @sessionModelIdentityNotReported.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent does not report this session’s confirmed provider and model. Choose a model explicitly to change this session; cancelling leaves it unchanged.'**
  String get sessionModelIdentityNotReported;

  /// No description provided for @sessionModelChooseExplicitly.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider and model from the current catalog.'**
  String get sessionModelChooseExplicitly;

  /// No description provided for @sessionModelResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matching models} =1{1 matching model} other{{count} matching models}}'**
  String sessionModelResultCount(int count);

  /// No description provided for @sessionModelSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {provider} — {model}'**
  String sessionModelSelected(String provider, String model);

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

  /// No description provided for @transcriptExportLoadedNote.
  ///
  /// In en, this message translates to:
  /// **'Copy or save all currently loaded turns. Older unfetched history is not included. Files contain the same redacted text as copy, up to 4 MiB; large transcripts may be rejected without truncation.'**
  String get transcriptExportLoadedNote;

  /// No description provided for @transcriptSaveTextAction.
  ///
  /// In en, this message translates to:
  /// **'Save as text'**
  String get transcriptSaveTextAction;

  /// No description provided for @transcriptSaveMarkdownAction.
  ///
  /// In en, this message translates to:
  /// **'Save as Markdown'**
  String get transcriptSaveMarkdownAction;

  /// No description provided for @transcriptExportUnsupported.
  ///
  /// In en, this message translates to:
  /// **'File export is available in the browser and on Linux only.'**
  String get transcriptExportUnsupported;

  /// No description provided for @transcriptExportOwnerChanged.
  ///
  /// In en, this message translates to:
  /// **'The conversation changed. Open transcript actions again to export it.'**
  String get transcriptExportOwnerChanged;

  /// No description provided for @transcriptExportDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Transcript download requested. Check your browser downloads for the file.'**
  String get transcriptExportDownloadStarted;

  /// No description provided for @transcriptExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Transcript saved to the selected file.'**
  String get transcriptExportSaved;

  /// No description provided for @transcriptExportTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This loaded transcript is too large to export (4 MiB limit). No file was written; content was not truncated.'**
  String get transcriptExportTooLarge;

  /// No description provided for @transcriptExportFailed.
  ///
  /// In en, this message translates to:
  /// **'The transcript could not be exported. No success was confirmed. Try again explicitly.'**
  String get transcriptExportFailed;

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

  /// No description provided for @transcriptCopyFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not copy transcript. Try again.'**
  String get transcriptCopyFailedMessage;

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

  /// No description provided for @sessionStreamingReply.
  ///
  /// In en, this message translates to:
  /// **'Streaming reply'**
  String get sessionStreamingReply;

  /// No description provided for @sessionReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Reply failed'**
  String get sessionReplyFailed;

  /// No description provided for @transcriptImageFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get transcriptImageFallbackLabel;

  /// No description provided for @chatImageAttachmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'IMAGE'**
  String get chatImageAttachmentTypeLabel;

  /// No description provided for @chatFileAttachmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'FILE'**
  String get chatFileAttachmentTypeLabel;

  /// No description provided for @chatImageAttachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Image attachment: {name}'**
  String chatImageAttachmentLabel(String name);

  /// No description provided for @chatFileAttachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'File attachment: {name}'**
  String chatFileAttachmentLabel(String name);

  /// No description provided for @chatFileExtensionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'{extension} FILE'**
  String chatFileExtensionTypeLabel(String extension);

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

  /// No description provided for @codeCopyFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not copy code. Try again.'**
  String get codeCopyFailedMessage;

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

  /// No description provided for @chatReasoningThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get chatReasoningThinking;

  /// No description provided for @chatReasoningThought.
  ///
  /// In en, this message translates to:
  /// **'Thought'**
  String get chatReasoningThought;

  /// No description provided for @localCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wing commands'**
  String get localCommandsTitle;

  /// No description provided for @localCommandsKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'↑↓ navigate  •  Enter select  •  Tab complete'**
  String get localCommandsKeyboardHint;

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
  /// **'Open gateway-scoped profiles.'**
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
  /// **'Show the selected profile persona.'**
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
  /// **'This profile has no persona content.'**
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

  /// No description provided for @desktopSessionsShortcutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sessions ({modifier}+K)'**
  String desktopSessionsShortcutTooltip(String modifier);

  /// No description provided for @desktopNewSessionShortcutTooltip.
  ///
  /// In en, this message translates to:
  /// **'New session ({modifier}+N)'**
  String desktopNewSessionShortcutTooltip(String modifier);

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
  /// **'Show server-reported usage for the latest Hermes run.'**
  String get localCommandUsageDescription;

  /// No description provided for @noRunTokenUsageMessage.
  ///
  /// In en, this message translates to:
  /// **'No server-reported Hermes run usage is available yet.'**
  String get noRunTokenUsageMessage;

  /// No description provided for @runTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'Latest Hermes run · {inputTokens} input · {outputTokens} output · {totalTokens} total'**
  String runTokenUsage(int inputTokens, int outputTokens, int totalTokens);

  /// No description provided for @transcriptRunTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'Latest Hermes run usage: {inputTokens} input · {outputTokens} output · {totalTokens} total tokens'**
  String transcriptRunTokenUsage(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  );

  /// No description provided for @runTokenUsageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Latest Hermes run token usage: {inputTokens} input, {outputTokens} output, {totalTokens} total. Input can include instructions, conversation context, and tool results; this is not a billing estimate.'**
  String runTokenUsageSemantics(
    int inputTokens,
    int outputTokens,
    int totalTokens,
  );

  /// No description provided for @runTokenUsageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Latest server-reported Hermes run. Input may include instructions, conversation context, and tool results. This is not a billing estimate.'**
  String get runTokenUsageTooltip;

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

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get diagnosticsConnectionSection;

  /// No description provided for @diagnosticsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get diagnosticsStatusLabel;

  /// No description provided for @diagnosticsStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get diagnosticsStatusDisconnected;

  /// No description provided for @diagnosticsStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get diagnosticsStatusConnecting;

  /// No description provided for @diagnosticsStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get diagnosticsStatusConnected;

  /// No description provided for @diagnosticsStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get diagnosticsStatusError;

  /// No description provided for @diagnosticsModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get diagnosticsModelLabel;

  /// No description provided for @diagnosticsModelNotReported.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get diagnosticsModelNotReported;

  /// No description provided for @diagnosticsRunTransportLabel.
  ///
  /// In en, this message translates to:
  /// **'Run transport'**
  String get diagnosticsRunTransportLabel;

  /// No description provided for @diagnosticsTransportNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get diagnosticsTransportNotConnected;

  /// No description provided for @diagnosticsTransportRunsSse.
  ///
  /// In en, this message translates to:
  /// **'Runs SSE enabled'**
  String get diagnosticsTransportRunsSse;

  /// No description provided for @diagnosticsTransportSessionStream.
  ///
  /// In en, this message translates to:
  /// **'Session chat streaming'**
  String get diagnosticsTransportSessionStream;

  /// No description provided for @diagnosticsTransportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get diagnosticsTransportUnavailable;

  /// No description provided for @diagnosticsVersionHealthLabel.
  ///
  /// In en, this message translates to:
  /// **'Version / health'**
  String get diagnosticsVersionHealthLabel;

  /// No description provided for @diagnosticsNoHealthDetails.
  ///
  /// In en, this message translates to:
  /// **'No health details yet'**
  String get diagnosticsNoHealthDetails;

  /// No description provided for @diagnosticsUnknownVersion.
  ///
  /// In en, this message translates to:
  /// **'unknown version'**
  String get diagnosticsUnknownVersion;

  /// No description provided for @diagnosticsUnknownGateway.
  ///
  /// In en, this message translates to:
  /// **'unknown gateway'**
  String get diagnosticsUnknownGateway;

  /// No description provided for @diagnosticsHealthSummary.
  ///
  /// In en, this message translates to:
  /// **'{version} • {gateway}'**
  String diagnosticsHealthSummary(String version, String gateway);

  /// No description provided for @diagnosticsInventorySection.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get diagnosticsInventorySection;

  /// No description provided for @diagnosticsResourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get diagnosticsResourcesLabel;

  /// No description provided for @diagnosticsResourcesSummary.
  ///
  /// In en, this message translates to:
  /// **'{models, plural, one{1 model} other{{models} models}} • {skills, plural, one{1 skill} other{{skills} skills}} • {toolsets, plural, one{1 toolset} other{{toolsets} toolsets}} • {jobs, plural, one{1 job} other{{jobs} jobs}}'**
  String diagnosticsResourcesSummary(
    int models,
    int skills,
    int toolsets,
    int jobs,
  );

  /// No description provided for @diagnosticsInventoryWarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Inventory warnings'**
  String get diagnosticsInventoryWarningsLabel;

  /// No description provided for @diagnosticsUnavailableSummary.
  ///
  /// In en, this message translates to:
  /// **'{resources} unavailable'**
  String diagnosticsUnavailableSummary(String resources);

  /// No description provided for @diagnosticsResourceHealth.
  ///
  /// In en, this message translates to:
  /// **'health'**
  String get diagnosticsResourceHealth;

  /// No description provided for @diagnosticsResourceModels.
  ///
  /// In en, this message translates to:
  /// **'models'**
  String get diagnosticsResourceModels;

  /// No description provided for @diagnosticsResourceSkills.
  ///
  /// In en, this message translates to:
  /// **'skills'**
  String get diagnosticsResourceSkills;

  /// No description provided for @diagnosticsResourceToolsets.
  ///
  /// In en, this message translates to:
  /// **'toolsets'**
  String get diagnosticsResourceToolsets;

  /// No description provided for @diagnosticsResourceJobs.
  ///
  /// In en, this message translates to:
  /// **'jobs'**
  String get diagnosticsResourceJobs;

  /// No description provided for @diagnosticsSessionsSection.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get diagnosticsSessionsSection;

  /// No description provided for @diagnosticsSessionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions • active {active}'**
  String diagnosticsSessionsSummary(int count, String active);

  /// No description provided for @diagnosticsActiveYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get diagnosticsActiveYes;

  /// No description provided for @diagnosticsActiveNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get diagnosticsActiveNone;

  /// No description provided for @diagnosticsExportSection.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get diagnosticsExportSection;

  /// No description provided for @diagnosticsCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get diagnosticsCopyTitle;

  /// No description provided for @diagnosticsCopyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Copying diagnostics'**
  String get diagnosticsCopyInProgress;

  /// No description provided for @diagnosticsCopySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Safe snapshot; excludes secrets, raw logs, transcripts, and local paths.'**
  String get diagnosticsCopySubtitle;

  /// No description provided for @diagnosticsCopiedNotice.
  ///
  /// In en, this message translates to:
  /// **'Hermes diagnostics copied'**
  String get diagnosticsCopiedNotice;

  /// No description provided for @diagnosticsCopyFailedNotice.
  ///
  /// In en, this message translates to:
  /// **'Could not copy diagnostics. Try again.'**
  String get diagnosticsCopyFailedNotice;

  /// No description provided for @voiceSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice & speech'**
  String get voiceSettingsTitle;

  /// No description provided for @voiceBehaviorSection.
  ///
  /// In en, this message translates to:
  /// **'Voice behavior'**
  String get voiceBehaviorSection;

  /// No description provided for @voiceContinuousTitle.
  ///
  /// In en, this message translates to:
  /// **'Continuous voice'**
  String get voiceContinuousTitle;

  /// No description provided for @voiceContinuousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send recognized speech to Hermes automatically.'**
  String get voiceContinuousSubtitle;

  /// No description provided for @voiceSpeakRepliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Speak replies aloud'**
  String get voiceSpeakRepliesTitle;

  /// No description provided for @voiceSpeakRepliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read replies aloud when hands-free voice is on.'**
  String get voiceSpeakRepliesSubtitle;

  /// No description provided for @voiceCompletionSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Response completion sound'**
  String get voiceCompletionSoundTitle;

  /// No description provided for @voiceCompletionSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when a reply finishes.'**
  String get voiceCompletionSoundSubtitle;

  /// No description provided for @voiceAdvancedSection.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get voiceAdvancedSection;

  /// No description provided for @voiceRecognitionLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Recognition language'**
  String get voiceRecognitionLanguageTitle;

  /// No description provided for @voiceRecognitionLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic lets the device recognizer choose; fixed modes request one language.'**
  String get voiceRecognitionLanguageSubtitle;

  /// No description provided for @voiceCommandWordTitle.
  ///
  /// In en, this message translates to:
  /// **'Command word'**
  String get voiceCommandWordTitle;

  /// No description provided for @voiceCommandWordHint.
  ///
  /// In en, this message translates to:
  /// **'Say this before “stop”, “pause”, “mute”, or “cancel” while the foreground voice loop is listening.'**
  String get voiceCommandWordHint;

  /// No description provided for @voiceRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get voiceRemoveAction;

  /// No description provided for @settingsGatewaysSection.
  ///
  /// In en, this message translates to:
  /// **'Gateways'**
  String get settingsGatewaysSection;

  /// No description provided for @settingsNoSavedGateways.
  ///
  /// In en, this message translates to:
  /// **'No saved Hermes gateways'**
  String get settingsNoSavedGateways;

  /// No description provided for @settingsConnectAnotherGateway.
  ///
  /// In en, this message translates to:
  /// **'Connect another gateway'**
  String get settingsConnectAnotherGateway;

  /// No description provided for @settingsScanPairingQr.
  ///
  /// In en, this message translates to:
  /// **'Connect directly to Hermes Agent.'**
  String get settingsScanPairingQr;

  /// No description provided for @settingsCredentialsNote.
  ///
  /// In en, this message translates to:
  /// **'Credentials stay in secure storage; values hidden'**
  String get settingsCredentialsNote;

  /// No description provided for @settingsVoiceSummary.
  ///
  /// In en, this message translates to:
  /// **'Voice input, spoken replies, and sounds'**
  String get settingsVoiceSummary;

  /// No description provided for @settingsVoiceSection.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get settingsVoiceSection;

  /// No description provided for @settingsGatewayActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Gateway actions for {label}'**
  String settingsGatewayActionsTooltip(String label);

  /// No description provided for @settingsManageAgentsAction.
  ///
  /// In en, this message translates to:
  /// **'Manage profiles'**
  String get settingsManageAgentsAction;

  /// No description provided for @settingsRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get settingsRenameAction;

  /// No description provided for @settingsUpdateConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Update connection'**
  String get settingsUpdateConnectionAction;

  /// No description provided for @settingsReconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get settingsReconnectAction;

  /// No description provided for @settingsConnectGatewayError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to this gateway.'**
  String get settingsConnectGatewayError;

  /// No description provided for @settingsReconnectGatewayError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh host status.'**
  String get settingsReconnectGatewayError;

  /// No description provided for @settingsRenameGatewayError.
  ///
  /// In en, this message translates to:
  /// **'Could not rename gateway.'**
  String get settingsRenameGatewayError;

  /// No description provided for @settingsUpdateConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not update gateway connection.'**
  String get settingsUpdateConnectionError;

  /// No description provided for @settingsRemoveGatewayError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove gateway.'**
  String get settingsRemoveGatewayError;

  /// No description provided for @settingsRenameGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename gateway'**
  String get settingsRenameGatewayTitle;

  /// No description provided for @settingsGatewayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway name'**
  String get settingsGatewayNameLabel;

  /// No description provided for @settingsUpdateConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Update gateway connection'**
  String get settingsUpdateConnectionTitle;

  /// No description provided for @settingsGatewayUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes gateway URL'**
  String get settingsGatewayUrlLabel;

  /// No description provided for @settingsGatewayUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'HTTPS or trusted private-network origin'**
  String get settingsGatewayUrlHelper;

  /// No description provided for @settingsNewTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'New access token (optional)'**
  String get settingsNewTokenLabel;

  /// No description provided for @settingsNewTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the saved token. Its current value is never shown.'**
  String get settingsNewTokenHelper;

  /// No description provided for @settingsClearTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove saved access token'**
  String get settingsClearTokenTitle;

  /// No description provided for @settingsClearTokenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use only when this gateway no longer requires it.'**
  String get settingsClearTokenSubtitle;

  /// No description provided for @settingsActiveGatewayNote.
  ///
  /// In en, this message translates to:
  /// **'Return to All chats before changing the active gateway connection.'**
  String get settingsActiveGatewayNote;

  /// No description provided for @settingsSaveAndReconnect.
  ///
  /// In en, this message translates to:
  /// **'Save and reconnect'**
  String get settingsSaveAndReconnect;

  /// No description provided for @settingsGatewayOriginError.
  ///
  /// In en, this message translates to:
  /// **'Enter an HTTP or HTTPS gateway origin.'**
  String get settingsGatewayOriginError;

  /// No description provided for @settingsRemoveGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove gateway?'**
  String get settingsRemoveGatewayTitle;

  /// No description provided for @settingsRemoveGatewayBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {label} and its saved credential from this device?'**
  String settingsRemoveGatewayBody(String label);

  /// No description provided for @enrollIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect directly to an existing Hermes Agent using Local, SSH, or Remote.'**
  String get enrollIntro;

  /// No description provided for @enrollOptionalSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Local setup'**
  String get enrollOptionalSetupAction;

  /// No description provided for @enrollPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Manual on-phone Hermes Agent setup in Termux. Installation and readiness are not verified by Wing.'**
  String get enrollPhoneHelp;

  /// No description provided for @enrollBackToOptions.
  ///
  /// In en, this message translates to:
  /// **'Connection options'**
  String get enrollBackToOptions;

  /// No description provided for @enrollLinuxHelp.
  ///
  /// In en, this message translates to:
  /// **'Inspect Hermes-home directory metadata and connect directly to Agent. Prepare and start Agent separately; discovery does not prove readiness.'**
  String get enrollLinuxHelp;

  /// No description provided for @enrollTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Hermes'**
  String get enrollTitle;

  /// No description provided for @enrollLegacyHandoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairing links are no longer supported'**
  String get enrollLegacyHandoffTitle;

  /// No description provided for @enrollLegacyHandoffBody.
  ///
  /// In en, this message translates to:
  /// **'This old link or shared text was discarded. Connect directly to Hermes Agent using Local, SSH or Remote. On Android, use SSH, Remote or the on-phone Termux guide. Existing saved connections are unchanged.'**
  String get enrollLegacyHandoffBody;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @routeNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFoundTitle;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing does not have a screen for {path}.'**
  String routeNotFound(String path);

  /// No description provided for @routeNotFoundAction.
  ///
  /// In en, this message translates to:
  /// **'Return to chat'**
  String get routeNotFoundAction;

  /// No description provided for @soulConnectionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to edit a persona'**
  String get soulConnectionRequiredTitle;

  /// No description provided for @soulConnectionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Open a saved gateway chat before editing its selected profile persona.'**
  String get soulConnectionRequiredBody;

  /// No description provided for @soulOpenChatAction.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get soulOpenChatAction;

  /// No description provided for @soulProfileRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile'**
  String get soulProfileRequiredTitle;

  /// No description provided for @soulProfileRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Select a profile before opening its persona editor.'**
  String get soulProfileRequiredBody;

  /// No description provided for @soulOpenProfilesAction.
  ///
  /// In en, this message translates to:
  /// **'Open profiles'**
  String get soulOpenProfilesAction;

  /// No description provided for @soulUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Persona editing unavailable'**
  String get soulUnavailableTitle;

  /// No description provided for @soulUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This gateway did not advertise scoped SOUL read and write operations for the selected profile.'**
  String get soulUnavailableBody;

  /// No description provided for @agentsGatewayPickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Add and edit profiles on the selected gateway.'**
  String get agentsGatewayPickerHelp;

  /// No description provided for @gatewayContactsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first Hermes profile'**
  String get gatewayContactsEmptyTitle;

  /// No description provided for @gatewayContactsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect a gateway to see its profiles and start a conversation.'**
  String get gatewayContactsEmptyBody;

  /// No description provided for @gatewayContactsConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Add Hermes'**
  String get gatewayContactsConnectAction;

  /// No description provided for @chatGroupsNewAction.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get chatGroupsNewAction;

  /// No description provided for @chatGroupsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get chatGroupsNewTitle;

  /// No description provided for @chatGroupsRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get chatGroupsRenameTitle;

  /// No description provided for @chatGroupsRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get chatGroupsRenameAction;

  /// No description provided for @chatGroupsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatGroupsDeleteAction;

  /// No description provided for @chatGroupsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get chatGroupsNameLabel;

  /// No description provided for @chatGroupsUngrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get chatGroupsUngrouped;

  /// No description provided for @chatGroupsMoveAction.
  ///
  /// In en, this message translates to:
  /// **'Move to group'**
  String get chatGroupsMoveAction;

  /// No description provided for @chatQueuedCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Cancel {count} queued follow-up?} other{Cancel {count} queued follow-ups?}}'**
  String chatQueuedCancelTitle(int count);

  /// No description provided for @chatQueuedMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String chatQueuedMore(int count);

  /// No description provided for @chatQueuedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Queued {count} follow-up after current reply: {preview}} other{Queued {count} follow-ups after current reply: {preview}}}'**
  String chatQueuedSummary(int count, String preview);

  /// No description provided for @chatQueuedWaitingForTransport.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a supported Hermes chat transport.'**
  String get chatQueuedWaitingForTransport;

  /// No description provided for @chatQueuedWaitingForOriginalSession.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the original session.'**
  String get chatQueuedWaitingForOriginalSession;

  /// No description provided for @chatQueuedRedactedNote.
  ///
  /// In en, this message translates to:
  /// **'Queued text is redacted and bounded in this confirmation.'**
  String get chatQueuedRedactedNote;

  /// No description provided for @chatQueuedAttachmentPreview.
  ///
  /// In en, this message translates to:
  /// **'Attachment: {name}'**
  String chatQueuedAttachmentPreview(String name);

  /// No description provided for @chatQueuedKeepAction.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get chatQueuedKeepAction;

  /// No description provided for @chatQueuedCancelAllAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get chatQueuedCancelAllAction;

  /// No description provided for @chatQueuedManageAction.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get chatQueuedManageAction;

  /// No description provided for @chatQueuedMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More queued follow-up actions'**
  String get chatQueuedMoreActions;

  /// No description provided for @chatQueuedManageTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} queued follow-up} other{{count} queued follow-ups}}'**
  String chatQueuedManageTitle(int count);

  /// No description provided for @chatQueuedCancelOneAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel queued follow-up'**
  String get chatQueuedCancelOneAction;

  /// No description provided for @chatQueuedFullError.
  ///
  /// In en, this message translates to:
  /// **'Queued follow-ups are full ({count}). Wait for Hermes to finish before adding more.'**
  String chatQueuedFullError(int count);

  /// No description provided for @chatQueuedOpenSessionError.
  ///
  /// In en, this message translates to:
  /// **'Could not open queued follow-up session: {message}'**
  String chatQueuedOpenSessionError(String message);

  /// No description provided for @chatQueuedSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send queued follow-up: {message}'**
  String chatQueuedSendError(String message);

  /// No description provided for @chatSteerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not guide the active Hermes run: {message}'**
  String chatSteerFailed(String message);

  /// No description provided for @chatConnectionRenameProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Hermes profile'**
  String get chatConnectionRenameProfileTitle;

  /// No description provided for @chatConnectionProfileLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile label'**
  String get chatConnectionProfileLabelLabel;

  /// No description provided for @chatConnectionProfileLabelHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to show the endpoint URL.'**
  String get chatConnectionProfileLabelHelper;

  /// No description provided for @chatConnectionRenameProfileErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Could not rename Hermes profile: {error}'**
  String chatConnectionRenameProfileErrorBody(String error);

  /// No description provided for @chatConnectionCleartextWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Send API key without TLS?'**
  String get chatConnectionCleartextWarningTitle;

  /// No description provided for @chatConnectionCleartextWarningBody.
  ///
  /// In en, this message translates to:
  /// **'The endpoint {endpoint} uses plain HTTP. Continue only on a trusted NetBird or Tailscale network, another trusted VPN, or an isolated LAN. Prefer HTTPS for remote Hermes endpoints.'**
  String chatConnectionCleartextWarningBody(String endpoint);

  /// No description provided for @chatConnectionContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get chatConnectionContinueAction;

  /// No description provided for @chatConnectionDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from Hermes?'**
  String get chatConnectionDisconnectTitle;

  /// No description provided for @chatConnectionDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Disconnect chat from {target}? Your saved connection stays on this device, so you can reconnect. Hermes Agent keeps running on the host.'**
  String chatConnectionDisconnectBody(String target);

  /// No description provided for @chatConnectionDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes diagnostics'**
  String get chatConnectionDiagnosticsTitle;

  /// No description provided for @chatConnectionRawLogStatusCopiedBody.
  ///
  /// In en, this message translates to:
  /// **'Raw-log status copied'**
  String get chatConnectionRawLogStatusCopiedBody;

  /// No description provided for @chatConnectionCopyRawLogStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Copy raw-log status'**
  String get chatConnectionCopyRawLogStatusAction;

  /// No description provided for @chatConnectionDiagnosticsCopiedBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes diagnostics copied'**
  String get chatConnectionDiagnosticsCopiedBody;

  /// No description provided for @chatConnectionCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatConnectionCopyAction;

  /// No description provided for @chatConnectionDisconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get chatConnectionDisconnectAction;

  /// No description provided for @chatSessionActionCreateFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not create session: {error}'**
  String chatSessionActionCreateFailedBody(String error);

  /// No description provided for @chatSessionActionOpenFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not open session: {error}'**
  String chatSessionActionOpenFailedBody(String error);

  /// No description provided for @chatSessionActionRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename session'**
  String get chatSessionActionRenameTitle;

  /// No description provided for @chatSessionActionTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Session title'**
  String get chatSessionActionTitleFieldLabel;

  /// No description provided for @chatSessionActionRenameFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not rename session: {error}'**
  String chatSessionActionRenameFailedBody(String error);

  /// No description provided for @chatSessionActionBranchTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch this session?'**
  String get chatSessionActionBranchTitle;

  /// No description provided for @chatSessionActionBranchBody.
  ///
  /// In en, this message translates to:
  /// **'Create a new session with the conversation history from “{title}”? The original remains in Hermes and the new branch becomes active.'**
  String chatSessionActionBranchBody(String title);

  /// No description provided for @chatSessionActionBranchConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Create branch'**
  String get chatSessionActionBranchConfirmAction;

  /// No description provided for @chatSessionActionBranchCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'Created a new session branch.'**
  String get chatSessionActionBranchCreatedBody;

  /// No description provided for @chatSessionActionBranchFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not create session branch: {error}'**
  String chatSessionActionBranchFailedBody(String error);

  /// No description provided for @chatSessionActionDeleteManyTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete {count} session?} other{Delete {count} sessions?}}'**
  String chatSessionActionDeleteManyTitle(int count);

  /// No description provided for @chatSessionActionDeleteManyBody.
  ///
  /// In en, this message translates to:
  /// **'Delete the selected sessions from Hermes? This cannot be undone.'**
  String get chatSessionActionDeleteManyBody;

  /// No description provided for @chatSessionActionDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatSessionActionDeleteAction;

  /// No description provided for @chatSessionActionDeletedCountBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Deleted {count} session.} other{Deleted {count} sessions.}}'**
  String chatSessionActionDeletedCountBody(int count);

  /// No description provided for @chatSessionActionDeletedPartialBody.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted} of {count} sessions. {failed} could not be deleted.'**
  String chatSessionActionDeletedPartialBody(
    int deleted,
    int count,
    int failed,
  );

  /// No description provided for @chatSessionActionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get chatSessionActionDeleteTitle;

  /// No description provided for @chatSessionActionDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from Hermes?'**
  String chatSessionActionDeleteBody(String title);

  /// No description provided for @chatSessionActionDeleteFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not delete session: {error}'**
  String chatSessionActionDeleteFailedBody(String error);

  /// No description provided for @chatUnsupportedAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Hermes Wing or Hermes Agent'**
  String get chatUnsupportedAgentTitle;

  /// No description provided for @chatUnsupportedAgentBody.
  ///
  /// In en, this message translates to:
  /// **'This Hermes Agent uses a capability format that this version of Hermes Wing cannot safely operate. Update Hermes Wing or Hermes Agent, then reconnect.'**
  String get chatUnsupportedAgentBody;

  /// No description provided for @chatTranscriptLoadEarlierAction.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get chatTranscriptLoadEarlierAction;

  /// No description provided for @chatTranscriptLoadingEarlierLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading earlier messages…'**
  String get chatTranscriptLoadingEarlierLabel;

  /// No description provided for @chatTranscriptCopyChatTextAction.
  ///
  /// In en, this message translates to:
  /// **'Copy entire chat (text)'**
  String get chatTranscriptCopyChatTextAction;

  /// No description provided for @chatTranscriptCopyChatMarkdownAction.
  ///
  /// In en, this message translates to:
  /// **'Copy entire chat (Markdown)'**
  String get chatTranscriptCopyChatMarkdownAction;

  /// No description provided for @chatTranscriptReplyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatTranscriptReplyAction;

  /// No description provided for @chatTranscriptCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatTranscriptCopyAction;

  /// No description provided for @chatTranscriptReadAloudAction.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get chatTranscriptReadAloudAction;

  /// No description provided for @chatTranscriptReadingAloudLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading aloud'**
  String get chatTranscriptReadingAloudLabel;

  /// No description provided for @chatTranscriptStopReadAloudAction.
  ///
  /// In en, this message translates to:
  /// **'Stop reading aloud'**
  String get chatTranscriptStopReadAloudAction;

  /// No description provided for @chatTranscriptMessageCopiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get chatTranscriptMessageCopiedLabel;

  /// No description provided for @chatTranscriptFullTimestamp.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String chatTranscriptFullTimestamp(String date, String time);

  /// No description provided for @chatTranscriptTimestampJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatTranscriptTimestampJustNow;

  /// No description provided for @chatTranscriptTimestampMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String chatTranscriptTimestampMinutesAgo(int count);

  /// No description provided for @chatTranscriptTimestampHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String chatTranscriptTimestampHoursAgo(int count);

  /// No description provided for @chatTranscriptTimestampDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String chatTranscriptTimestampDaysAgo(int count);

  /// No description provided for @chatTranscriptToolStatusNeedsAttentionLabel.
  ///
  /// In en, this message translates to:
  /// **'Host action needs attention'**
  String get chatTranscriptToolStatusNeedsAttentionLabel;

  /// No description provided for @chatTranscriptToolStatusRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Working on Hermes host'**
  String get chatTranscriptToolStatusRunningLabel;

  /// No description provided for @chatTranscriptToolStatusCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed on Hermes host'**
  String get chatTranscriptToolStatusCompletedLabel;

  /// No description provided for @chatTranscriptHostActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes host activity'**
  String get chatTranscriptHostActivityTitle;

  /// No description provided for @chatTranscriptToolCategoryWeb.
  ///
  /// In en, this message translates to:
  /// **'Web activity'**
  String get chatTranscriptToolCategoryWeb;

  /// No description provided for @chatTranscriptToolCategoryBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser activity'**
  String get chatTranscriptToolCategoryBrowser;

  /// No description provided for @chatTranscriptToolCategoryFiles.
  ///
  /// In en, this message translates to:
  /// **'File activity'**
  String get chatTranscriptToolCategoryFiles;

  /// No description provided for @chatTranscriptToolCategoryCode.
  ///
  /// In en, this message translates to:
  /// **'Code activity'**
  String get chatTranscriptToolCategoryCode;

  /// No description provided for @chatTranscriptToolCategoryVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice activity'**
  String get chatTranscriptToolCategoryVoice;

  /// No description provided for @chatTranscriptToolCategoryMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory activity'**
  String get chatTranscriptToolCategoryMemory;

  /// No description provided for @chatTranscriptToolCategoryDelegation.
  ///
  /// In en, this message translates to:
  /// **'Delegated activity'**
  String get chatTranscriptToolCategoryDelegation;

  /// No description provided for @chatTranscriptToolCategorySchedule.
  ///
  /// In en, this message translates to:
  /// **'Scheduled activity'**
  String get chatTranscriptToolCategorySchedule;

  /// No description provided for @chatTranscriptHostActivityCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes host activity · {count} steps'**
  String chatTranscriptHostActivityCountTitle(int count);

  /// No description provided for @chatTranscriptHostStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Host step {step}'**
  String chatTranscriptHostStepTitle(int step);

  /// No description provided for @chatTranscriptToolActivitySingleTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool activity: {name}'**
  String chatTranscriptToolActivitySingleTitle(String name);

  /// No description provided for @chatTranscriptToolActivityCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool activity: {count} calls'**
  String chatTranscriptToolActivityCountTitle(int count);

  /// No description provided for @chatTranscriptActionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Action blocked'**
  String get chatTranscriptActionBlockedTitle;

  /// No description provided for @chatTranscriptHideDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get chatTranscriptHideDetailsAction;

  /// No description provided for @chatTranscriptDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get chatTranscriptDetailsAction;

  /// No description provided for @chatErrorAuthRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes API rejected the saved API key.'**
  String get chatErrorAuthRejectedTitle;

  /// No description provided for @chatErrorAuthRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Reconnect with a fresh Hermes API key, then retry this message.'**
  String get chatErrorAuthRejectedBody;

  /// No description provided for @chatErrorProviderUsageExhaustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider usage limit reached.'**
  String get chatErrorProviderUsageExhaustedTitle;

  /// No description provided for @chatErrorProviderUsageExhaustedBody.
  ///
  /// In en, this message translates to:
  /// **'Choose another provider or model, or wait for the provider\'s usage limit to reset.'**
  String get chatErrorProviderUsageExhaustedBody;

  /// No description provided for @chatErrorOpenProvidersAction.
  ///
  /// In en, this message translates to:
  /// **'Switch provider or model'**
  String get chatErrorOpenProvidersAction;

  /// No description provided for @chatErrorApprovalResponseFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes could not record the approval decision.'**
  String get chatErrorApprovalResponseFailedTitle;

  /// No description provided for @chatErrorApprovalResponseFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Review the request, check that the run is still active, then try the decision again.'**
  String get chatErrorApprovalResponseFailedBody;

  /// No description provided for @chatErrorMalformedApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes sent an incomplete approval request.'**
  String get chatErrorMalformedApprovalTitle;

  /// No description provided for @chatErrorMalformedApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'Retry when Hermes can provide an approval id for this run.'**
  String get chatErrorMalformedApprovalBody;

  /// No description provided for @chatErrorUnsupportedTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes endpoint does not support chat turns.'**
  String get chatErrorUnsupportedTransportTitle;

  /// No description provided for @chatErrorUnsupportedTransportBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Hermes API server that advertises session chat streaming or run events.'**
  String get chatErrorUnsupportedTransportBody;

  /// No description provided for @chatErrorRunStillActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes run is still active.'**
  String get chatErrorRunStillActiveTitle;

  /// No description provided for @chatErrorRunStillActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to reconcile this run before sending it again.'**
  String get chatErrorRunStillActiveBody;

  /// No description provided for @chatErrorRunCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes run was cancelled.'**
  String get chatErrorRunCancelledTitle;

  /// No description provided for @chatErrorRunCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'Start a new turn when you are ready.'**
  String get chatErrorRunCancelledBody;

  /// No description provided for @chatErrorRunFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes run failed.'**
  String get chatErrorRunFailedTitle;

  /// No description provided for @chatErrorRunFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check Hermes, then retry this message when the run is recoverable.'**
  String get chatErrorRunFailedBody;

  /// No description provided for @chatErrorStreamDroppedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes stream dropped.'**
  String get chatErrorStreamDroppedTitle;

  /// No description provided for @chatErrorStreamDroppedBody.
  ///
  /// In en, this message translates to:
  /// **'Check the endpoint/network and send again when Hermes is reachable.'**
  String get chatErrorStreamDroppedBody;

  /// No description provided for @chatErrorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes could not finish the turn.'**
  String get chatErrorGenericTitle;

  /// No description provided for @chatErrorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Retry when Hermes is ready.'**
  String get chatErrorGenericBody;

  /// No description provided for @chatErrorDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get chatErrorDetailsAction;

  /// No description provided for @chatErrorUpdateKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Update key'**
  String get chatErrorUpdateKeyAction;

  /// No description provided for @chatErrorReconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get chatErrorReconnectAction;

  /// No description provided for @chatErrorRetryLastMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Retry last message'**
  String get chatErrorRetryLastMessageAction;

  /// No description provided for @chatErrorRedactedDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Redacted error details'**
  String get chatErrorRedactedDetailsLabel;

  /// No description provided for @chatErrorRedactionNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Secrets, bearer tokens, API keys, cookies, and copied endpoint credentials are redacted before display.'**
  String get chatErrorRedactionNoteBody;

  /// No description provided for @chatErrorCopiedRedactedDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Copied redacted Hermes error details.'**
  String get chatErrorCopiedRedactedDetailsBody;

  /// No description provided for @chatErrorCopyRedactedDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Copy redacted details'**
  String get chatErrorCopyRedactedDetailsAction;

  /// No description provided for @chatErrorSavedProfilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved Hermes profiles'**
  String get chatErrorSavedProfilesLabel;

  /// No description provided for @chatErrorRenameProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename Hermes profile'**
  String get chatErrorRenameProfileTooltip;

  /// No description provided for @chatErrorRemoveProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove saved Hermes profile?'**
  String get chatErrorRemoveProfileTitle;

  /// No description provided for @chatErrorRemoveProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {label} ({baseUrl}) from this device. Any stored API key for this profile is removed from secure storage.'**
  String chatErrorRemoveProfileBody(String label, String baseUrl);

  /// No description provided for @chatErrorRemoveProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatErrorRemoveProfileAction;

  /// No description provided for @chatErrorConnectAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes API rejected the API key.'**
  String get chatErrorConnectAuthTitle;

  /// No description provided for @chatErrorConnectAuthBody.
  ///
  /// In en, this message translates to:
  /// **'Check the endpoint API key in Hermes and try again.'**
  String get chatErrorConnectAuthBody;

  /// No description provided for @chatErrorConnectInvalidEndpointTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the Hermes address.'**
  String get chatErrorConnectInvalidEndpointTitle;

  /// No description provided for @chatErrorConnectInvalidEndpointBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a complete HTTP or HTTPS Hermes Agent URL, then try again.'**
  String get chatErrorConnectInvalidEndpointBody;

  /// No description provided for @chatErrorConnectIncompatibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes returned an unsupported response.'**
  String get chatErrorConnectIncompatibleTitle;

  /// No description provided for @chatErrorConnectIncompatibleBody.
  ///
  /// In en, this message translates to:
  /// **'Update Hermes Wing or Hermes Agent, verify the address points to Hermes Agent, then reconnect.'**
  String get chatErrorConnectIncompatibleBody;

  /// No description provided for @chatErrorConnectTlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure connection to Hermes failed.'**
  String get chatErrorConnectTlsTitle;

  /// No description provided for @chatErrorConnectTlsBody.
  ///
  /// In en, this message translates to:
  /// **'Check the HTTPS certificate or trusted host identity. If the identity changed, verify it through a trusted administrator before reconnecting.'**
  String get chatErrorConnectTlsBody;

  /// No description provided for @chatErrorConnectTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes did not respond in time.'**
  String get chatErrorConnectTimeoutTitle;

  /// No description provided for @chatErrorConnectTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'Check that Hermes Agent is running and reachable, then try again.'**
  String get chatErrorConnectTimeoutBody;

  /// No description provided for @chatErrorConnectUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes endpoint is unreachable.'**
  String get chatErrorConnectUnreachableTitle;

  /// No description provided for @chatErrorConnectUnreachableBody.
  ///
  /// In en, this message translates to:
  /// **'Check the base URL, network, VPN, and that Hermes API server is running.'**
  String get chatErrorConnectUnreachableBody;

  /// No description provided for @chatErrorConnectGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Hermes.'**
  String get chatErrorConnectGenericTitle;

  /// No description provided for @chatErrorConnectGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Check the endpoint and try again.'**
  String get chatErrorConnectGenericBody;

  /// No description provided for @chatLayoutConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Hermes'**
  String get chatLayoutConnectTitle;

  /// No description provided for @chatLayoutConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect directly to Hermes Agent. Choose how this device can reach it.'**
  String get chatLayoutConnectBody;

  /// No description provided for @chatLayoutConnectionModeLabel.
  ///
  /// In en, this message translates to:
  /// **'How will Wing reach Hermes?'**
  String get chatLayoutConnectionModeLabel;

  /// No description provided for @chatLayoutConnectionModeLocalLabel.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get chatLayoutConnectionModeLocalLabel;

  /// No description provided for @chatLayoutConnectionPrimaryRemoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get chatLayoutConnectionPrimaryRemoteLabel;

  /// No description provided for @chatLayoutConnectionModeRemoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote HTTPS'**
  String get chatLayoutConnectionModeRemoteLabel;

  /// No description provided for @chatLayoutConnectionModeVpnLabel.
  ///
  /// In en, this message translates to:
  /// **'VPN / NetBird / Tailscale'**
  String get chatLayoutConnectionModeVpnLabel;

  /// No description provided for @chatLayoutConnectionModeSshLabel.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get chatLayoutConnectionModeSshLabel;

  /// No description provided for @chatLayoutConnectionModeLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Use a local Agent URL, or install Hermes on this device when local setup is available.'**
  String get chatLayoutConnectionModeLocalBody;

  /// No description provided for @chatLayoutConnectionModeRemoteBody.
  ///
  /// In en, this message translates to:
  /// **'Use an HTTPS Agent URL. Wing currently uses HTTPS/SSE; authenticated WebSocket support waits for an exact Hermes contract.'**
  String get chatLayoutConnectionModeRemoteBody;

  /// No description provided for @chatLayoutRemoteAuthExplanation.
  ///
  /// In en, this message translates to:
  /// **'Connect directly to a Hermes Agent endpoint with its Agent access token. A host-management token or provider API key is not an Agent access token.\n\nBrowser OAuth sign-in is not supported in Wing. An OAuth-only server cannot currently connect through this flow. If access is denied, check the endpoint and its Agent token with the server administrator, then retry explicitly or cancel. A denial does not identify the server\'s sign-in method.'**
  String get chatLayoutRemoteAuthExplanation;

  /// No description provided for @chatLayoutConnectionModeVpnBody.
  ///
  /// In en, this message translates to:
  /// **'Use the Agent URL reachable through your trusted encrypted NetBird or Tailscale network, or another trusted VPN. Prefer HTTPS; non-local HTTP requires explicit confirmation. Wing does not treat network location as authorization.'**
  String get chatLayoutConnectionModeVpnBody;

  /// No description provided for @chatLayoutConnectionModeSshBody.
  ///
  /// In en, this message translates to:
  /// **'Start a fixed, trusted SSH tunnel outside Wing, then enter its local Agent URL. Wing never runs arbitrary SSH commands or stores SSH keys.'**
  String get chatLayoutConnectionModeSshBody;

  /// No description provided for @chatLayoutConnectionModeLocalUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the local Agent URL. This device usually uses http://127.0.0.1:8642.'**
  String get chatLayoutConnectionModeLocalUrlHelper;

  /// No description provided for @chatLayoutConnectionModeRemoteUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the HTTPS Agent URL. Wing currently uses HTTPS/SSE; WebSocket support waits for an exact Hermes contract.'**
  String get chatLayoutConnectionModeRemoteUrlHelper;

  /// No description provided for @chatLayoutConnectionModeVpnUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the Agent URL reachable through your trusted encrypted NetBird or Tailscale network, or another trusted VPN.'**
  String get chatLayoutConnectionModeVpnUrlHelper;

  /// No description provided for @chatLayoutConnectionModeSshUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Start the fixed tunnel outside Wing, then enter the local Agent URL it exposes.'**
  String get chatLayoutConnectionModeSshUrlHelper;

  /// No description provided for @chatLayoutVpsConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent connection'**
  String get chatLayoutVpsConnectionTitle;

  /// No description provided for @chatLayoutVpsConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Use an HTTPS or trusted private-network URL. Never expose an unauthenticated Hermes port to the internet.'**
  String get chatLayoutVpsConnectionBody;

  /// No description provided for @chatLayoutScanQrAction.
  ///
  /// In en, this message translates to:
  /// **'Pairing links are no longer supported'**
  String get chatLayoutScanQrAction;

  /// No description provided for @chatLayoutServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent URL'**
  String get chatLayoutServerUrlLabel;

  /// No description provided for @chatLayoutServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://hermes.example.com'**
  String get chatLayoutServerUrlHint;

  /// No description provided for @chatLayoutServerUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the Agent URL without /v1. For a trusted local or SSH tunnel, a loopback HTTP URL may be used.'**
  String get chatLayoutServerUrlHelper;

  /// No description provided for @chatLayoutAccessTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get chatLayoutAccessTokenLabel;

  /// No description provided for @chatLayoutAccessTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Required for internet-facing servers; optional only on trusted private networks.'**
  String get chatLayoutAccessTokenHelper;

  /// No description provided for @chatLayoutShowAccessTokenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show access token'**
  String get chatLayoutShowAccessTokenTooltip;

  /// No description provided for @chatLayoutHideAccessTokenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide access token'**
  String get chatLayoutHideAccessTokenTooltip;

  /// No description provided for @chatLayoutVpsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection name (optional)'**
  String get chatLayoutVpsNameLabel;

  /// No description provided for @chatLayoutVpsNameHint.
  ///
  /// In en, this message translates to:
  /// **'My Hermes connection'**
  String get chatLayoutVpsNameHint;

  /// No description provided for @chatLayoutVpsNameHelper.
  ///
  /// In en, this message translates to:
  /// **'A private label shown only on this device.'**
  String get chatLayoutVpsNameHelper;

  /// No description provided for @chatLayoutTokenStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Saving a connection uses secure device storage. Connecting alone does not confirm that your token was saved.'**
  String get chatLayoutTokenStorageBody;

  /// No description provided for @chatLayoutCredentialBoundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent credential only'**
  String get chatLayoutCredentialBoundaryTitle;

  /// No description provided for @chatLayoutCredentialBoundaryBody.
  ///
  /// In en, this message translates to:
  /// **'This token is only for Hermes Agent access. SSH authentication and provider credentials are separate.'**
  String get chatLayoutCredentialBoundaryBody;

  /// No description provided for @chatLayoutConnectingAction.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get chatLayoutConnectingAction;

  /// No description provided for @chatLayoutConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Add Hermes'**
  String get chatLayoutConnectAction;

  /// No description provided for @chatLayoutDevShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to a local Agent?'**
  String get chatLayoutDevShortcutsTitle;

  /// No description provided for @chatLayoutDevShortcutsBody.
  ///
  /// In en, this message translates to:
  /// **'Use a development shortcut instead of a VPS address.'**
  String get chatLayoutDevShortcutsBody;

  /// No description provided for @chatLayoutPresetThisDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get chatLayoutPresetThisDeviceLabel;

  /// No description provided for @chatLayoutPresetAndroidEmulatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Android emulator'**
  String get chatLayoutPresetAndroidEmulatorLabel;

  /// No description provided for @chatLayoutPresetClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear server details'**
  String get chatLayoutPresetClearAction;

  /// No description provided for @chatLayoutModelFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes model'**
  String get chatLayoutModelFallbackLabel;

  /// No description provided for @chatComposerModelPickerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose model'**
  String get chatComposerModelPickerTooltip;

  /// No description provided for @chatComposerModelsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Models could not be loaded from Hermes.'**
  String get chatComposerModelsLoadFailed;

  /// No description provided for @chatLayoutTransportUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes did not advertise a supported chat transport for this endpoint.'**
  String get chatLayoutTransportUnavailableBody;

  /// No description provided for @chatLayoutOpenSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Open session'**
  String get chatLayoutOpenSessionAction;

  /// No description provided for @chatLayoutFollowUpsCopiedBody.
  ///
  /// In en, this message translates to:
  /// **'Copied redacted Hermes queued follow-ups.'**
  String get chatLayoutFollowUpsCopiedBody;

  /// No description provided for @chatLayoutCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatLayoutCopyAction;

  /// No description provided for @chatLayoutSendNowAction.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get chatLayoutSendNowAction;

  /// No description provided for @chatLayoutCancelAllAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get chatLayoutCancelAllAction;

  /// No description provided for @chatLayoutNoSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'No Hermes sessions. Create a new session to start chatting.'**
  String get chatLayoutNoSessionsBody;

  /// No description provided for @chatLayoutNoSessionsNoCreateBody.
  ///
  /// In en, this message translates to:
  /// **'No Hermes sessions are available, and this endpoint did not advertise session creation.'**
  String get chatLayoutNoSessionsNoCreateBody;

  /// No description provided for @chatLayoutVoiceLoopOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice loop on'**
  String get chatLayoutVoiceLoopOnLabel;

  /// No description provided for @chatLayoutVoiceReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice ready'**
  String get chatLayoutVoiceReadyLabel;

  /// No description provided for @chatVoiceCaptureTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Voice capture timed out.'**
  String get chatVoiceCaptureTimedOut;

  /// No description provided for @chatVoiceMicrophonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Grant microphone access in system settings, then return to Hermes Wing.'**
  String get chatVoiceMicrophonePermissionDenied;

  /// No description provided for @chatVoiceDeviceLanguageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device speech recognition has no offline language for this device locale. Install that language\'s offline speech data in Android settings, then return to Hermes Wing.'**
  String get chatVoiceDeviceLanguageUnavailable;

  /// No description provided for @chatVoiceDeviceSpeechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device speech recognition is unavailable. Install or enable device speech recognition, then return to Hermes Wing.'**
  String get chatVoiceDeviceSpeechUnavailable;

  /// No description provided for @chatVoiceNoSpeechDetected.
  ///
  /// In en, this message translates to:
  /// **'No speech was recognized. Tap Speak, wait for Listening, then speak clearly and close to the microphone.'**
  String get chatVoiceNoSpeechDetected;

  /// No description provided for @chatVoiceCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice capture failed: {detail}'**
  String chatVoiceCaptureFailed(String detail);

  /// No description provided for @chatVoiceCaptureFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Voice capture failed.'**
  String get chatVoiceCaptureFailedFallback;

  /// No description provided for @chatVoiceCaptureSessionChanged.
  ///
  /// In en, this message translates to:
  /// **'Voice capture was discarded because the Hermes session changed.'**
  String get chatVoiceCaptureSessionChanged;

  /// No description provided for @chatVoiceInputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available here.'**
  String get chatVoiceInputUnavailable;

  /// No description provided for @chatVoiceTurnSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice turn could not be sent: {detail}'**
  String chatVoiceTurnSendFailed(String detail);

  /// No description provided for @chatVoiceTurnSendFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Voice turn could not be sent.'**
  String get chatVoiceTurnSendFailedFallback;

  /// No description provided for @chatVoiceShutdownTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Voice shutdown timed out. Continuous voice paused.'**
  String get chatVoiceShutdownTimedOut;

  /// No description provided for @chatVoiceShutdownFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice shutdown failed. Continuous voice paused.'**
  String get chatVoiceShutdownFailed;

  /// No description provided for @chatVoicePlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice playback is unavailable for this connection. The reply is available as text. Voice input remains available from the microphone.'**
  String get chatVoicePlaybackUnavailable;

  /// No description provided for @chatVoicePlaybackUnavailableContinuous.
  ///
  /// In en, this message translates to:
  /// **'Voice playback is unavailable for this connection. The reply is available as text. Hands-free listening stopped. Voice input remains available from the microphone.'**
  String get chatVoicePlaybackUnavailableContinuous;

  /// No description provided for @chatVoicePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice playback failed. The reply is available as text. Voice input remains available from the microphone.'**
  String get chatVoicePlaybackFailed;

  /// No description provided for @chatVoicePlaybackFailedContinuous.
  ///
  /// In en, this message translates to:
  /// **'Voice playback failed. The reply is available as text. Hands-free listening stopped. Voice input remains available from the microphone.'**
  String get chatVoicePlaybackFailedContinuous;

  /// No description provided for @chatVoicePlaybackSessionChanged.
  ///
  /// In en, this message translates to:
  /// **'Hermes session changed before the spoken reply finished.'**
  String get chatVoicePlaybackSessionChanged;

  /// No description provided for @chatVoicePlaybackSessionChangedContinuous.
  ///
  /// In en, this message translates to:
  /// **'Hermes session changed before voice could re-arm. Continuous voice paused.'**
  String get chatVoicePlaybackSessionChangedContinuous;

  /// No description provided for @chatVoicePausedByLocalCommand.
  ///
  /// In en, this message translates to:
  /// **'Continuous voice paused by local command.'**
  String get chatVoicePausedByLocalCommand;

  /// No description provided for @chatVoiceSessionChangedContinuous.
  ///
  /// In en, this message translates to:
  /// **'Hermes session changed. Continuous voice paused.'**
  String get chatVoiceSessionChangedContinuous;

  /// No description provided for @chatVoiceSessionChangedSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Hermes session changed. Spoken reply stopped.'**
  String get chatVoiceSessionChangedSpeaking;

  /// No description provided for @chatVoiceSessionChangedCapturing.
  ///
  /// In en, this message translates to:
  /// **'Hermes session changed. Voice capture stopped.'**
  String get chatVoiceSessionChangedCapturing;

  /// No description provided for @chatVoiceContinuousPaused.
  ///
  /// In en, this message translates to:
  /// **'{message} Continuous voice paused.'**
  String chatVoiceContinuousPaused(String message);

  /// No description provided for @chatLayoutComposerSpeakingHint.
  ///
  /// In en, this message translates to:
  /// **'Speaking reply…'**
  String get chatLayoutComposerSpeakingHint;

  /// No description provided for @chatLayoutComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message Hermes…'**
  String get chatLayoutComposerHint;

  /// No description provided for @chatLayoutComposerUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Chat unavailable'**
  String get chatLayoutComposerUnavailableHint;

  /// No description provided for @chatLayoutComposerTransportUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Chat transport unavailable'**
  String get chatLayoutComposerTransportUnavailableHint;

  /// No description provided for @chatLayoutComposerRunRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to reconcile the active run…'**
  String get chatLayoutComposerRunRecoveryHint;

  /// No description provided for @chatLayoutChatMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat menu'**
  String get chatLayoutChatMenuTooltip;

  /// No description provided for @chatLayoutSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get chatLayoutSessionsLabel;

  /// No description provided for @chatLayoutHandsFreeVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Hands-free voice'**
  String get chatLayoutHandsFreeVoiceLabel;

  /// No description provided for @chatLayoutEmojiTitle.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatLayoutEmojiTitle;

  /// No description provided for @chatLayoutInsertEmojiLabel.
  ///
  /// In en, this message translates to:
  /// **'Insert {value}'**
  String chatLayoutInsertEmojiLabel(String value);

  /// No description provided for @chatLayoutListeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get chatLayoutListeningLabel;

  /// No description provided for @chatLayoutSpeakingLabel.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get chatLayoutSpeakingLabel;

  /// No description provided for @chatLayoutHandsFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Hands-free'**
  String get chatLayoutHandsFreeLabel;

  /// No description provided for @chatLayoutContinuousVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Continuous voice — device STT to Hermes text'**
  String get chatLayoutContinuousVoiceLabel;

  /// No description provided for @chatLayoutAttachedFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Attached file {name}, ready to send'**
  String chatLayoutAttachedFileLabel(String name);

  /// No description provided for @chatLayoutReadyToSendLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get chatLayoutReadyToSendLabel;

  /// No description provided for @chatLayoutRemoveAttachmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get chatLayoutRemoveAttachmentTooltip;

  /// No description provided for @chatLayoutAttachFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach image or text file'**
  String get chatLayoutAttachFileTooltip;

  /// No description provided for @chatAttachmentPicking.
  ///
  /// In en, this message translates to:
  /// **'Opening the attachment picker'**
  String get chatAttachmentPicking;

  /// No description provided for @chatAttachmentRemoveCurrentError.
  ///
  /// In en, this message translates to:
  /// **'Remove the current attachment before adding another.'**
  String get chatAttachmentRemoveCurrentError;

  /// No description provided for @chatAttachmentInsertedImageReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the inserted image.'**
  String get chatAttachmentInsertedImageReadError;

  /// No description provided for @chatAttachmentImageSizeError.
  ///
  /// In en, this message translates to:
  /// **'Images must be 10 MB or smaller.'**
  String get chatAttachmentImageSizeError;

  /// No description provided for @chatAttachmentPastedImageTypeError.
  ///
  /// In en, this message translates to:
  /// **'Hermes accepts pasted PNG, JPEG, GIF, and WebP images.'**
  String get chatAttachmentPastedImageTypeError;

  /// No description provided for @chatAttachmentTextSizeError.
  ///
  /// In en, this message translates to:
  /// **'Text files must be 256 KB or smaller.'**
  String get chatAttachmentTextSizeError;

  /// No description provided for @chatAttachmentUnsupportedTypeError.
  ///
  /// In en, this message translates to:
  /// **'Hermes accepts PNG, JPEG, GIF, WebP, and UTF-8 text files; PDFs, binary files, and videos cannot be sent.'**
  String get chatAttachmentUnsupportedTypeError;

  /// No description provided for @chatAttachmentInvalidUtf8Error.
  ///
  /// In en, this message translates to:
  /// **'Text attachments must contain valid UTF-8.'**
  String get chatAttachmentInvalidUtf8Error;

  /// No description provided for @chatAttachmentOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open attachment: {error}'**
  String chatAttachmentOpenError(String error);

  /// No description provided for @chatLayoutStopSpeakingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop speaking'**
  String get chatLayoutStopSpeakingTooltip;

  /// No description provided for @chatLayoutSpeakAndSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start hands-free voice'**
  String get chatLayoutSpeakAndSendTooltip;

  /// No description provided for @chatLayoutSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatLayoutSendTooltip;

  /// No description provided for @chatLayoutVoiceOutputUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice output unavailable'**
  String get chatLayoutVoiceOutputUnavailableTitle;

  /// No description provided for @chatLayoutVoiceOutputUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The reply is available as text. Voice playback stopped, and hands-free listening is off. Voice input remains available from the microphone.'**
  String get chatLayoutVoiceOutputUnavailableBody;

  /// No description provided for @chatLayoutContinueInTextAction.
  ///
  /// In en, this message translates to:
  /// **'Continue in text'**
  String get chatLayoutContinueInTextAction;

  /// No description provided for @chatLocalArtifactUndeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Not delivered to this device'**
  String get chatLocalArtifactUndeliveredTitle;

  /// No description provided for @chatLocalAudioArtifactUndeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'A tool created audio on the Hermes host, but Wing did not receive a playable audio attachment. Use the text reply instead.'**
  String get chatLocalAudioArtifactUndeliveredBody;

  /// No description provided for @chatLocalMediaArtifactUndeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes referenced media on its host, but Wing did not receive an attachment. Ask Hermes to attach the file to deliver it to this device.'**
  String get chatLocalMediaArtifactUndeliveredBody;

  /// No description provided for @chatLocalFileArtifactUndeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes created a file on its host, but Wing did not receive an attachment. Ask Hermes to attach the file to deliver it to this device.'**
  String get chatLocalFileArtifactUndeliveredBody;

  /// No description provided for @chatShellVoicePausedBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes Wing stopped voice when it left the foreground. The microphone is off. Resume when you’re ready.'**
  String get chatShellVoicePausedBackgroundBody;

  /// No description provided for @chatShellVoicePausedSwitchingAgentsBody.
  ///
  /// In en, this message translates to:
  /// **'Continuous voice paused while switching profiles.'**
  String get chatShellVoicePausedSwitchingAgentsBody;

  /// No description provided for @chatShellApprovalAnswerFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not answer Hermes approval: {message}'**
  String chatShellApprovalAnswerFailedBody(String message);

  /// No description provided for @chatShellSwitchChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch chats?'**
  String get chatShellSwitchChatsTitle;

  /// No description provided for @chatShellSwitchChatsBody.
  ///
  /// In en, this message translates to:
  /// **'This gateway has active work or an approval. Switching closes its live streams; Hermes remains authoritative and will reconcile them when reopened.'**
  String get chatShellSwitchChatsBody;

  /// No description provided for @chatShellStayAction.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get chatShellStayAction;

  /// No description provided for @chatShellSwitchAction.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get chatShellSwitchAction;

  /// No description provided for @chatShellContactClosedBody.
  ///
  /// In en, this message translates to:
  /// **'Closed Hermes contact.'**
  String get chatShellContactClosedBody;

  /// No description provided for @chatShellContactSwitchedBody.
  ///
  /// In en, this message translates to:
  /// **'Switched Hermes contact.'**
  String get chatShellContactSwitchedBody;

  /// No description provided for @chatShellAllChatsTooltip.
  ///
  /// In en, this message translates to:
  /// **'All chats'**
  String get chatShellAllChatsTooltip;

  /// No description provided for @chatShellHermesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get chatShellHermesTitle;

  /// No description provided for @chatShellConnectAnotherGatewayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Hermes'**
  String get chatShellConnectAnotherGatewayTooltip;

  /// No description provided for @chatShellSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get chatShellSessionsLabel;

  /// No description provided for @chatShellNewSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get chatShellNewSessionLabel;

  /// No description provided for @chatShellMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get chatShellMoreActionsTooltip;

  /// No description provided for @chatShellDiagnosticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get chatShellDiagnosticsLabel;

  /// No description provided for @chatShellDisconnectLabel.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get chatShellDisconnectLabel;

  /// No description provided for @chatShellTranscriptSessionMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Session metadata'**
  String get chatShellTranscriptSessionMetadataTitle;

  /// No description provided for @chatShellTranscriptSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session: {title}'**
  String chatShellTranscriptSessionLabel(String title);

  /// No description provided for @chatShellTranscriptSessionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Session ID: {id}'**
  String chatShellTranscriptSessionIdLabel(String id);

  /// No description provided for @chatShellTranscriptMessageCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages: {count}'**
  String chatShellTranscriptMessageCountLabel(int count);

  /// No description provided for @chatStatusUnavailableInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Unavailable Hermes inventory'**
  String get chatStatusUnavailableInventoryTitle;

  /// No description provided for @chatStatusDetailedHealthLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed health'**
  String get chatStatusDetailedHealthLabel;

  /// No description provided for @chatStatusModelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get chatStatusModelsLabel;

  /// No description provided for @chatStatusSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get chatStatusSkillsLabel;

  /// No description provided for @chatStatusToolsetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Toolsets'**
  String get chatStatusToolsetsLabel;

  /// No description provided for @chatStatusJobsLabel.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get chatStatusJobsLabel;

  /// No description provided for @chatStatusJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes jobs'**
  String get chatStatusJobsTitle;

  /// No description provided for @chatStatusJobsReadOnlyAdminBody.
  ///
  /// In en, this message translates to:
  /// **'Read-only inventory. Hermes advertises jobs admin, but Hermes Wing has not enabled mobile create/edit/delete scheduling.'**
  String get chatStatusJobsReadOnlyAdminBody;

  /// No description provided for @chatStatusJobsReadOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Read-only inventory. Mobile create/edit/delete scheduling is not available.'**
  String get chatStatusJobsReadOnlyBody;

  /// No description provided for @chatStatusCopyJobDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy job details'**
  String get chatStatusCopyJobDetailsTooltip;

  /// No description provided for @chatStatusCopiedJobDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Copied redacted Hermes job details.'**
  String get chatStatusCopiedJobDetailsBody;

  /// No description provided for @chatStatusJobEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get chatStatusJobEnabledLabel;

  /// No description provided for @chatStatusJobDisabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get chatStatusJobDisabledLabel;

  /// No description provided for @chatStatusJobStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State: {value}'**
  String chatStatusJobStateLabel(String value);

  /// No description provided for @chatStatusJobScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule: {value}'**
  String chatStatusJobScheduleLabel(String value);

  /// No description provided for @chatStatusJobNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {value}'**
  String chatStatusJobNextLabel(String value);

  /// No description provided for @chatStatusJobLastLabel.
  ///
  /// In en, this message translates to:
  /// **'Last: {value}'**
  String chatStatusJobLastLabel(String value);

  /// No description provided for @chatStatusJobLastErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Last error: {value}'**
  String chatStatusJobLastErrorLabel(String value);

  /// No description provided for @chatStatusSurfaceReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes surface readiness'**
  String get chatStatusSurfaceReadinessTitle;

  /// No description provided for @chatStatusSurfaceReadinessNoteBody.
  ///
  /// In en, this message translates to:
  /// **'No mobile config, memory, schedule, or messaging-gateway mutation controls are enabled.'**
  String get chatStatusSurfaceReadinessNoteBody;

  /// No description provided for @chatStatusCopiedSurfaceReadinessBody.
  ///
  /// In en, this message translates to:
  /// **'Copied Hermes surface readiness summary.'**
  String get chatStatusCopiedSurfaceReadinessBody;

  /// No description provided for @chatStatusCopySurfaceReadinessFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not copy Hermes surface readiness summary. Try again.'**
  String get chatStatusCopySurfaceReadinessFailedBody;

  /// No description provided for @chatStatusCopySummaryAction.
  ///
  /// In en, this message translates to:
  /// **'Copy summary'**
  String get chatStatusCopySummaryAction;

  /// No description provided for @chatStatusRunsSseEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Runs SSE enabled'**
  String get chatStatusRunsSseEnabledLabel;

  /// No description provided for @chatStatusSessionChatStreamingLabel.
  ///
  /// In en, this message translates to:
  /// **'Session chat streaming enabled'**
  String get chatStatusSessionChatStreamingLabel;

  /// No description provided for @chatStatusVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice: device STT → Hermes'**
  String get chatStatusVoiceLabel;

  /// No description provided for @chatStatusVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String chatStatusVersionLabel(String version);

  /// No description provided for @chatStatusGatewayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway: {state}'**
  String chatStatusGatewayLabel(String state);

  /// No description provided for @chatStatusActiveAgentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active profiles: {count}'**
  String chatStatusActiveAgentsLabel(int count);

  /// No description provided for @chatStatusModelsChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Models: {names}'**
  String chatStatusModelsChipLabel(String names);

  /// No description provided for @chatStatusModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes models'**
  String get chatStatusModelsTitle;

  /// No description provided for @chatStatusSkillsChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills: {count}'**
  String chatStatusSkillsChipLabel(int count);

  /// No description provided for @chatStatusSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes skills'**
  String get chatStatusSkillsTitle;

  /// No description provided for @chatStatusToolsetsChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Toolsets enabled: {count}'**
  String chatStatusToolsetsChipLabel(int count);

  /// No description provided for @chatStatusToolsetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes toolsets'**
  String get chatStatusToolsetsTitle;

  /// No description provided for @chatStatusJobsChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Jobs: {count}'**
  String chatStatusJobsChipLabel(int count);

  /// No description provided for @chatStatusInventoryUnavailableChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Inventory unavailable: {count}'**
  String chatStatusInventoryUnavailableChipLabel(int count);

  /// No description provided for @chatStatusSurfacesChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Surfaces: {deferredCount} deferred · {blockedCount} blocked'**
  String chatStatusSurfacesChipLabel(int deferredCount, int blockedCount);

  /// No description provided for @chatStatusAgentHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent {model}'**
  String chatStatusAgentHeaderLabel(String model);

  /// No description provided for @chatStatusPendingApprovalsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} pending approvals}}'**
  String chatStatusPendingApprovalsLabel(int count);

  /// No description provided for @chatStatusApprovalRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes approval requested'**
  String get chatStatusApprovalRequestedTitle;

  /// No description provided for @chatStatusRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk: {risk}'**
  String chatStatusRiskLabel(String risk);

  /// No description provided for @chatStatusApprovalResponseUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes did not advertise approval responses for this run.'**
  String get chatStatusApprovalResponseUnavailableBody;

  /// No description provided for @chatStatusApprovalIdMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes sent this approval without a run or approval id, so it cannot be answered.'**
  String get chatStatusApprovalIdMissingBody;

  /// No description provided for @chatStatusAnsweringApprovalLabel.
  ///
  /// In en, this message translates to:
  /// **'Answering Hermes approval…'**
  String get chatStatusAnsweringApprovalLabel;

  /// No description provided for @chatStatusReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get chatStatusReviewAction;

  /// No description provided for @chatStatusDismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get chatStatusDismissAction;

  /// No description provided for @chatStatusDenyAction.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get chatStatusDenyAction;

  /// No description provided for @chatStatusAllowForSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Allow for session'**
  String get chatStatusAllowForSessionAction;

  /// No description provided for @chatStatusAlwaysAllowAction.
  ///
  /// In en, this message translates to:
  /// **'Always allow'**
  String get chatStatusAlwaysAllowAction;

  /// No description provided for @chatStatusApproveOnceAction.
  ///
  /// In en, this message translates to:
  /// **'Approve once'**
  String get chatStatusApproveOnceAction;

  /// No description provided for @chatStatusAllowForSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow this for the session?'**
  String get chatStatusAllowForSessionTitle;

  /// No description provided for @chatStatusAllowForSessionBody.
  ///
  /// In en, this message translates to:
  /// **'This may approve matching requests for the current Hermes session.'**
  String get chatStatusAllowForSessionBody;

  /// No description provided for @chatStatusAlwaysAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Always allow this Hermes approval?'**
  String get chatStatusAlwaysAllowTitle;

  /// No description provided for @chatStatusAlwaysAllowBody.
  ///
  /// In en, this message translates to:
  /// **'This may approve matching future requests without asking again.'**
  String get chatStatusAlwaysAllowBody;

  /// No description provided for @chatStatusReviewApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Hermes approval'**
  String get chatStatusReviewApprovalTitle;

  /// No description provided for @chatStatusReviewingPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviewing 1 of {count} pending approvals'**
  String chatStatusReviewingPendingLabel(int count);

  /// No description provided for @chatStatusPromptTruncatedBody.
  ///
  /// In en, this message translates to:
  /// **'Prompt preview truncated for mobile review.'**
  String get chatStatusPromptTruncatedBody;

  /// No description provided for @chatStatusRiskTruncatedBody.
  ///
  /// In en, this message translates to:
  /// **'Risk preview truncated for mobile review.'**
  String get chatStatusRiskTruncatedBody;

  /// No description provided for @chatStatusCommandTruncatedBody.
  ///
  /// In en, this message translates to:
  /// **'Command preview truncated for mobile review.'**
  String get chatStatusCommandTruncatedBody;

  /// No description provided for @chatStatusCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command: {value}'**
  String chatStatusCommandLabel(String value);

  /// No description provided for @chatStatusToolCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool call: {value}'**
  String chatStatusToolCallLabel(String value);

  /// No description provided for @chatStatusDecisionsDisabledEndpointBody.
  ///
  /// In en, this message translates to:
  /// **'Decision buttons are disabled because Hermes did not advertise /v1/runs/{run_id}/approval.'**
  String chatStatusDecisionsDisabledEndpointBody(String run_id);

  /// No description provided for @chatStatusDecisionsDisabledIdBody.
  ///
  /// In en, this message translates to:
  /// **'Decision buttons are disabled because Hermes did not include a run or approval id.'**
  String get chatStatusDecisionsDisabledIdBody;

  /// No description provided for @chatStatusCopiedApprovalDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Copied redacted Hermes approval details.'**
  String get chatStatusCopiedApprovalDetailsBody;

  /// No description provided for @chatStatusCopyDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get chatStatusCopyDetailsAction;

  /// No description provided for @chatRailSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get chatRailSessionsTitle;

  /// No description provided for @shellLoadedSessions.
  ///
  /// In en, this message translates to:
  /// **'Loaded sessions'**
  String get shellLoadedSessions;

  /// No description provided for @shellSessionScope.
  ///
  /// In en, this message translates to:
  /// **'Open or create. Manage sessions in Chat.'**
  String get shellSessionScope;

  /// No description provided for @shellSessionSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String shellSessionSource(String source);

  /// No description provided for @shellNewSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get shellNewSession;

  /// No description provided for @shellSessionPending.
  ///
  /// In en, this message translates to:
  /// **'Opening session…'**
  String get shellSessionPending;

  /// No description provided for @shellSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the session. Try again in Chat.'**
  String get shellSessionFailed;

  /// No description provided for @shellOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String shellOpenSession(String title);

  /// No description provided for @chatRailPinnedGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get chatRailPinnedGroupLabel;

  /// No description provided for @chatRailChatsGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatRailChatsGroupLabel;

  /// No description provided for @chatRailPinSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatRailPinSessionAction;

  /// No description provided for @chatRailUnpinSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatRailUnpinSessionAction;

  /// No description provided for @chatRailHermesSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hermes sessions'**
  String get chatRailHermesSessionsTitle;

  /// No description provided for @chatRailNewSessionAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get chatRailNewSessionAction;

  /// No description provided for @chatRailLoadMoreSessionsAction.
  ///
  /// In en, this message translates to:
  /// **'Load more sessions'**
  String get chatRailLoadMoreSessionsAction;

  /// No description provided for @chatRailLoadingMoreSessionsAction.
  ///
  /// In en, this message translates to:
  /// **'Loading more sessions…'**
  String get chatRailLoadingMoreSessionsAction;

  /// No description provided for @chatRailSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get chatRailSelectAction;

  /// No description provided for @chatRailSelectAllAction.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get chatRailSelectAllAction;

  /// No description provided for @chatRailSelectedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String chatRailSelectedCountLabel(int count);

  /// No description provided for @chatRailDeleteCountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete {count}'**
  String chatRailDeleteCountAction(int count);

  /// No description provided for @chatRailSearchSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search sessions'**
  String get chatRailSearchSessionsLabel;

  /// No description provided for @chatRailSourceFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by source'**
  String get chatRailSourceFilterLabel;

  /// No description provided for @chatRailAllSourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get chatRailAllSourcesLabel;

  /// No description provided for @chatRailClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get chatRailClearSearchTooltip;

  /// No description provided for @chatRailSessionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String chatRailSessionCountLabel(int count);

  /// No description provided for @chatRailShowingSessionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Showing {visible} of {total} session} other{Showing {visible} of {total} sessions}}'**
  String chatRailShowingSessionCountLabel(int total, int visible);

  /// No description provided for @chatRailNoSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet. Create one to start a Hermes chat.'**
  String get chatRailNoSessionsBody;

  /// No description provided for @chatRailNoSessionsMatchBody.
  ///
  /// In en, this message translates to:
  /// **'No sessions match “{query}”.'**
  String chatRailNoSessionsMatchBody(String query);

  /// No description provided for @chatRailNoHermesSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'No Hermes sessions yet.'**
  String get chatRailNoHermesSessionsBody;

  /// No description provided for @chatRailNoHermesSessionsMatchBody.
  ///
  /// In en, this message translates to:
  /// **'No Hermes sessions match “{query}”.'**
  String chatRailNoHermesSessionsMatchBody(String query);

  /// No description provided for @chatRailActiveHermesSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Hermes session'**
  String get chatRailActiveHermesSessionLabel;

  /// No description provided for @chatRailCycleActiveSessionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch live chats · Ctrl+Tab or Ctrl/Command+1–9'**
  String get chatRailCycleActiveSessionsTooltip;

  /// No description provided for @chatRailActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatRailActiveLabel;

  /// No description provided for @chatRailStatusStreamingLabel.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get chatRailStatusStreamingLabel;

  /// No description provided for @chatRailNewReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'New reply'**
  String get chatRailNewReplyLabel;

  /// No description provided for @chatRailStatusReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get chatRailStatusReadyLabel;

  /// No description provided for @chatRailStatusTransportUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Transport unavailable'**
  String get chatRailStatusTransportUnavailableLabel;

  /// No description provided for @chatRailMessageCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String chatRailMessageCountLabel(int count);

  /// No description provided for @chatRailTileMessageCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String chatRailTileMessageCountLabel(int count);

  /// No description provided for @chatRailEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'What are we working on?'**
  String get chatRailEmptyStateTitle;

  /// No description provided for @chatRailEmptyStateBody.
  ///
  /// In en, this message translates to:
  /// **'Ask Hermes a question, or start with one of these.'**
  String get chatRailEmptyStateBody;

  /// No description provided for @chatRailPromptSummarizeHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'What can you help me do?'**
  String get chatRailPromptSummarizeHelpLabel;

  /// No description provided for @chatRailPromptListSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show my available skills'**
  String get chatRailPromptListSkillsLabel;

  /// No description provided for @chatRailPromptPlanTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan my next coding task'**
  String get chatRailPromptPlanTaskLabel;

  /// No description provided for @chatRailPromptExplainSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Catch me up on this session'**
  String get chatRailPromptExplainSessionLabel;

  /// No description provided for @chatRailStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get chatRailStopAction;

  /// No description provided for @chatRailForkedFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Forked from {sessionId}'**
  String chatRailForkedFromLabel(String sessionId);

  /// No description provided for @chatRailLastActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Last active {timestamp}'**
  String chatRailLastActiveLabel(String timestamp);

  /// No description provided for @chatRailSessionActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Session actions'**
  String get chatRailSessionActionsTooltip;

  /// No description provided for @chatRailViewDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get chatRailViewDetailsAction;

  /// No description provided for @chatRailCopyDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get chatRailCopyDetailsAction;

  /// No description provided for @chatRailCopySessionIdAction.
  ///
  /// In en, this message translates to:
  /// **'Copy session ID'**
  String get chatRailCopySessionIdAction;

  /// No description provided for @chatRailCopiedSessionIdBody.
  ///
  /// In en, this message translates to:
  /// **'Copied session ID.'**
  String get chatRailCopiedSessionIdBody;

  /// No description provided for @chatRailCopySessionIdFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not copy session ID. Try again.'**
  String get chatRailCopySessionIdFailedBody;

  /// No description provided for @chatRailRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get chatRailRenameAction;

  /// No description provided for @chatRailBranchAction.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get chatRailBranchAction;

  /// No description provided for @chatRailDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatRailDeleteAction;

  /// No description provided for @chatRailCopiedSessionDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Copied redacted Hermes session details.'**
  String get chatRailCopiedSessionDetailsBody;

  /// No description provided for @chatRailCopySessionDetailsFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not copy session details. Please try again.'**
  String get chatRailCopySessionDetailsFailedBody;

  /// No description provided for @chatRailSessionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get chatRailSessionDetailsTitle;

  /// No description provided for @chatRailSessionDetailsHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Hermes session'**
  String get chatRailSessionDetailsHeaderLabel;

  /// No description provided for @chatRailDetailTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title: {value}'**
  String chatRailDetailTitleLabel(String value);

  /// No description provided for @chatRailDetailIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {value}'**
  String chatRailDetailIdLabel(String value);

  /// No description provided for @chatRailDetailActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active: {value}'**
  String chatRailDetailActiveLabel(String value);

  /// No description provided for @chatRailDetailMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages: {count}'**
  String chatRailDetailMessagesLabel(int count);

  /// No description provided for @chatRailDetailToolCallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool calls: {count}'**
  String chatRailDetailToolCallsLabel(int count);

  /// No description provided for @chatRailDetailApiCallsLabel.
  ///
  /// In en, this message translates to:
  /// **'API calls: {count}'**
  String chatRailDetailApiCallsLabel(int count);

  /// No description provided for @chatRailDetailInputTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Session input tokens: {count}'**
  String chatRailDetailInputTokensLabel(int count);

  /// No description provided for @chatRailDetailOutputTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Session output tokens: {count}'**
  String chatRailDetailOutputTokensLabel(int count);

  /// No description provided for @chatRailDetailCacheReadTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Session cache read tokens: {count}'**
  String chatRailDetailCacheReadTokensLabel(int count);

  /// No description provided for @chatRailDetailCacheWriteTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Session cache write tokens: {count}'**
  String chatRailDetailCacheWriteTokensLabel(int count);

  /// No description provided for @chatRailDetailReasoningTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Session reasoning tokens: {count}'**
  String chatRailDetailReasoningTokensLabel(int count);

  /// No description provided for @chatRailDetailActualCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual cost (USD): {cost}'**
  String chatRailDetailActualCostLabel(String cost);

  /// No description provided for @chatRailDetailEstimatedCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost (USD): {cost}'**
  String chatRailDetailEstimatedCostLabel(String cost);

  /// No description provided for @chatRailDetailStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started: {value}'**
  String chatRailDetailStartedLabel(String value);

  /// No description provided for @chatRailDetailEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'Ended: {value}'**
  String chatRailDetailEndedLabel(String value);

  /// No description provided for @chatRailDetailEndReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'End reason: {value}'**
  String chatRailDetailEndReasonLabel(String value);

  /// No description provided for @chatRailDetailSystemPromptSnapshotLabel.
  ///
  /// In en, this message translates to:
  /// **'System prompt snapshot: {value}'**
  String chatRailDetailSystemPromptSnapshotLabel(String value);

  /// No description provided for @chatRailDetailModelConfigSnapshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Model config snapshot: {value}'**
  String chatRailDetailModelConfigSnapshotLabel(String value);

  /// No description provided for @chatRailDetailYesLabel.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get chatRailDetailYesLabel;

  /// No description provided for @chatRailDetailNoLabel.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get chatRailDetailNoLabel;

  /// No description provided for @chatRailDetailForkedFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Forked from: {value}'**
  String chatRailDetailForkedFromLabel(String value);

  /// No description provided for @chatRailDetailLastActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Last active: {value}'**
  String chatRailDetailLastActiveLabel(String value);

  /// No description provided for @modelPresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get modelPresetsLabel;

  /// No description provided for @modelPresetSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save preset'**
  String get modelPresetSaveAction;

  /// No description provided for @modelPresetSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save model preset'**
  String get modelPresetSaveTitle;

  /// No description provided for @modelPresetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get modelPresetNameLabel;

  /// No description provided for @modelPresetUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Not in this gateway\'s catalog'**
  String get modelPresetUnavailableBody;

  /// No description provided for @credentialProbeLatency.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String credentialProbeLatency(int ms);

  /// No description provided for @credentialProbeModelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 model available} other{{count} models available}}'**
  String credentialProbeModelCount(int count);

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsChatSection.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get settingsChatSection;

  /// No description provided for @chatSpellcheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check spelling'**
  String get chatSpellcheckTitle;

  /// No description provided for @chatSpellcheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the platform spell checker while composing messages'**
  String get chatSpellcheckSubtitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themePaletteLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get themePaletteLabel;

  /// No description provided for @themePaletteWing.
  ///
  /// In en, this message translates to:
  /// **'Wing'**
  String get themePaletteWing;

  /// No description provided for @themePaletteIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get themePaletteIndigo;

  /// No description provided for @themePaletteForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themePaletteForest;

  /// No description provided for @themePaletteAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themePaletteAmber;

  /// No description provided for @themePaletteMulberry.
  ///
  /// In en, this message translates to:
  /// **'Mulberry'**
  String get themePaletteMulberry;

  /// No description provided for @tipMoreDestinations.
  ///
  /// In en, this message translates to:
  /// **'Chat, Profiles, and Connections are below. Schedules, Providers, Tools, Persona, and Settings live under More.'**
  String get tipMoreDestinations;

  /// No description provided for @tipVoice.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to talk. Hold it to dictate and review before sending.'**
  String get tipVoice;

  /// No description provided for @tipApprovals.
  ///
  /// In en, this message translates to:
  /// **'Hermes asks before sensitive actions. Review each request, then approve once, allow for the session, always allow, or deny.'**
  String get tipApprovals;

  /// No description provided for @tipDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss tip'**
  String get tipDismissTooltip;

  /// No description provided for @toolsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading tools'**
  String get toolsLoading;

  /// No description provided for @gatewayLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading gateway status'**
  String get gatewayLoading;

  /// No description provided for @schedulesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading schedules'**
  String get schedulesLoading;

  /// No description provided for @localSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Use this computer (Local)'**
  String get localSetupAction;

  /// No description provided for @termuxCopyFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The setup command could not be copied. Select the command and copy it manually.'**
  String get termuxCopyFailedMessage;

  /// No description provided for @enrollInstallOnPhoneAction.
  ///
  /// In en, this message translates to:
  /// **'Use this phone (Termux)'**
  String get enrollInstallOnPhoneAction;
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
