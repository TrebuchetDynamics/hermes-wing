// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get skillsAllCategoriesLabel => 'All categories';

  @override
  String get skillsCategoriesLabel => 'Categories';

  @override
  String get settingsChatDisplayHeading => 'Chat display';

  @override
  String get chatTextDirectionTitle => 'Text direction';

  @override
  String get chatTextDirectionAuto => 'Auto';

  @override
  String get chatTextDirectionRtl => 'Right to left';

  @override
  String get chatTextDirectionLtr => 'Left to right';

  @override
  String get chatBotOpen => 'Bot Chat';

  @override
  String get chatBotGap =>
      'Canonical Bot Chat requires supported native Agent operations and settled history/replay. Ordinary sessions remain available; reconcile active work before switching.';

  @override
  String get chatBotFailure =>
      'Bot Chat could not be confirmed. Your current conversation is unchanged. Retry explicitly; no message was sent.';

  @override
  String get historyJsonAction => 'Export paged history as JSON';

  @override
  String get historyJsonConsent =>
      'This fetches private, unredacted session history, including ancestor, compacted and tool content. Attachment URLs and HTML remain inert data. This is paged history, not a frozen snapshot: external same-length edits can evade checks. It is not an Agent backup or proof of atomic completeness. Preparation is limited to 60 seconds and 4 MiB. Cancel discards this attempt; a file write already started may still finish.';

  @override
  String get historyJsonPrepare => 'Prepare private JSON';

  @override
  String historyJsonProgress(int count) {
    return 'Preparing JSON: $count messages fetched';
  }

  @override
  String historyJsonReady(int count) {
    return 'Paged history prepared: $count messages. Save this private file only to a trusted destination.';
  }

  @override
  String get historyJsonSave => 'Save JSON';

  @override
  String get historyJsonCancel => 'Cancel export';

  @override
  String get historyJsonCancelled => 'Save cancelled before writing.';

  @override
  String get historyJsonFailed =>
      'History export was discarded. The read failed, exceeded its limits, was cancelled, or its owner changed. Close and explicitly retry to start at page zero.';

  @override
  String get transcriptOverwriteTitle => 'Save and allow replacement?';

  @override
  String get transcriptOverwriteBody =>
      'Save to the selected local destination? Any file there at write time will be replaced, including one created by another app while this dialog is open. Cancelling afterward cannot undo a write that already started.';

  @override
  String get transcriptOverwriteConfirm => 'Save and allow replacement';

  @override
  String get managedSshAdvanced => 'Advanced';

  @override
  String get managedSshSaveTarget => 'Save SSH settings';

  @override
  String get managedSshLoadTarget => 'Use saved SSH settings';

  @override
  String get managedSshTargetBody =>
      'Save the destination on this device without passwords, keys or tokens.';

  @override
  String get managedSshTargetSaved =>
      'SSH settings saved securely. Authentication is still required.';

  @override
  String get managedSshTargetLoaded =>
      'Saved SSH settings loaded. Enter credentials, then Connect.';

  @override
  String get managedSshTargetMissing => 'No saved SSH settings on this device.';

  @override
  String get managedSshTargetFailure =>
      'SSH settings could not be saved or loaded securely.';

  @override
  String get managedSshServeReads => 'Read Hermes serve through SSH';

  @override
  String get managedSshServeReadsBody =>
      'Use the host-provided serve session token, not API_SERVER_KEY. Reads profiles, sessions and history. Chat requires separate ticket authentication. SSH settings can be saved separately; credentials and automatic restoration are not saved. No automatic protocol fallback.';

  @override
  String get localServeReadsLabel =>
      'Read an already-running Hermes serve backend';

  @override
  String get localServeReadsBody =>
      'Linux loopback only. Enter this backend\'s host-provided session token, not API_SERVER_KEY or a provider key. Reads profiles, sessions and history. Chat requires a separately authenticated ticket connection; legacy local tokens may allow reads only. No launch or credential discovery. This connection and token are not saved; enter them again after relaunch.';

  @override
  String get localServeEnableChat => 'Enable chat on this session';

  @override
  String get localServeReconcile => 'Reconcile this session without resending';

  @override
  String get localServeStopRequested =>
      'Stop requested. Waiting for Hermes to confirm completion; closing the connection does not confirm Stop.';

  @override
  String get localServeTokenLabel => 'Hermes serve session token';

  @override
  String get connectionGuideTitle => 'Connect step by step';

  @override
  String get gatewayLoginTitle => 'Connect to Hermes Desktop';

  @override
  String get gatewayAddress => 'Hermes gateway HTTPS address';

  @override
  String get gatewayProfile => 'Hermes profile';

  @override
  String get gatewaySignIn => 'Authorize this phone';

  @override
  String get gatewayScan => 'Scan computer QR';

  @override
  String get gatewayQrCreate => 'Show connection QR';

  @override
  String get gatewayQrSafe =>
      'This QR contains only the gateway address and profile. It does not contain a token or authorize access. Both devices need a reachable private network; sign in on the phone to authorize it.';

  @override
  String get gatewayInvalidQr =>
      'Unsupported connection QR or address. Use an HTTPS gateway address with no key, query or fragment. Legacy pairing codes are not accepted.';

  @override
  String get gatewayCameraFailed =>
      'The camera is unavailable or permission was denied. Go back and enter the gateway address instead.';

  @override
  String get gatewayLoginBody =>
      'Enter the HTTPS address and sign in with your browser.';

  @override
  String get gatewayLoginFailed =>
      'Gateway sign-in or connection could not be completed. Check the address, trusted HTTPS certificate and native sign-in support. No message was sent. Retry explicitly.';

  @override
  String get gatewayLoginPending =>
      'Waiting for authorization in your browser…';

  @override
  String get gatewayReconnect => 'Connect to my Hermes';

  @override
  String get gatewayForget => 'Forget gateway sign-in';

  @override
  String get gatewayStorageFailed =>
      'Secure sign-in storage is unavailable. Access was not confirmed as remembered.';

  @override
  String get managedSshQuickTitle => 'Your saved Hermes';

  @override
  String get managedSshQuickConnect => 'Connect to my Hermes';

  @override
  String get managedSshQuickBody =>
      'Reconnect using this phone\'s secure saved access. Host identity and Agent authorization are checked again. No messages are resent.';

  @override
  String get managedSshQuickRemember => 'Remember this connection';

  @override
  String get managedSshQuickConsent =>
      'Save the SSH password or key, key passphrase and Agent token securely on this phone.';

  @override
  String get managedSshQuickEdit => 'Use different connection details';

  @override
  String get managedSshQuickForget => 'Forget saved access';

  @override
  String get managedSshQuickStorageFailed =>
      'Saved access could not be read or removed. Your credentials were not displayed. Retry or enter connection details manually.';

  @override
  String get managedSshQuickSaveFailed =>
      'Connected, but remembering access was not confirmed. Continue without saving, or reconnect later to try again.';

  @override
  String get managedSshQuickContinue => 'Continue with this connection';

  @override
  String get connectionAccessTitle => 'I need access to Hermes';

  @override
  String get connectionAccessBody =>
      'Already chatting with Hermes on your computer? Copy the request below and send it there. Hermes can help prepare access on its own host. No address or token from this form is copied. If someone else manages your server, send the request to them instead. Return here with the exact API address and enter the credential only in the masked token field.';

  @override
  String get connectionAccessCopy => 'Copy request for Hermes';

  @override
  String get connectionAccessPreview => 'Read the request before sending';

  @override
  String get connectionAccessCopied =>
      'Request copied. Paste it in your existing Hermes chat. No connection values or secrets were included.';

  @override
  String get connectionAccessRequest =>
      'Help me connect Hermes Wing to this Hermes installation using its supported authenticated Agent API. First inspect the existing setup without changing it. Confirm the intended profile and whether Wing will run on this same device or another one. Give me the exact reachable API base address, preserving any /p/<profile> prefix and omitting the final /v1. Do not assume localhost on my phone reaches this computer. Explain how to enter the existing API_SERVER_KEY securely in Wing\'s masked field without displaying it in chat, logs, URLs, clipboard or command arguments. Do not rotate existing credentials. If the API is not enabled, explain the required supported setup and ask before any configuration change or shared gateway restart. Keep loopback private; do not open firewall ports or expose the server. For another device, explain supported SSH forwarding or an already-approved HTTPS/VPN route. Do not install Wing Link or another management service, modify Hermes source, or claim a dashboard/OAuth credential is an API-server key. Finish by separating what was actually verified from any remaining manual step. Do not send a test message or run model inference automatically.';

  @override
  String get connectionGuidePrepare => '1. Prepare Hermes Agent';

  @override
  String get connectionGuidePrepareBody =>
      'On the computer running Agent, open the official Hermes dashboard with hermes dashboard. Choose the intended profile, then Channels → API server. Enable the API on loopback for this computer, or ask the host administrator for a trusted HTTPS endpoint. Wing does not install or start Agent.';

  @override
  String get connectionGuideAddress => '2. Enter this profile\'s address';

  @override
  String get connectionGuideAddressBody =>
      'Run hermes gateway status on the Agent host to find its API address. In Wing, omit the final /v1. A shared gateway uses /p/<profile> for a named profile, for example http://127.0.0.1:8642/p/demo. Keep that prefix. On another device, 127.0.0.1 points to that device, not your computer.';

  @override
  String get connectionGuideToken => '3. Set up your access token';

  @override
  String get connectionGuideTokenBody =>
      'The Agent access token is API_SERVER_KEY, not an OpenAI or Nous provider key. In the official dashboard, select the same profile and open Channels → API server. Set a strong, unique secret in its masked API key field, or obtain the existing credential securely from the administrator. Enter that same secret in Wing\'s masked token field. Do not rotate an existing key without reviewing its other clients. If activation requires a gateway restart, the administrator must arrange it; a shared restart affects other profiles.';

  @override
  String get connectionGuideGenerateToken =>
      'Automatic token setup unavailable';

  @override
  String get connectionGuideGenerateTokenBody =>
      'This Agent API has no verified secure operation to generate, register and deliver an access token to Wing. A random value generated here would not grant access. Use the official Agent setup above; Wing never reads secret files or runs host configuration commands.';

  @override
  String get connectionGuideBrowser => '4. Allow this browser';

  @override
  String get connectionGuideBrowserBody =>
      'On the Agent host, allow the exact Wing origin below in API_SERVER_CORS_ORIGINS. Keep the allowlist narrow. A blocked browser origin cannot be repaired by changing the token. Wing does not change or restart your gateway.';

  @override
  String get connectionGuideVerify => 'Check, save, then chat';

  @override
  String get connectionGuideVerifyBody =>
      'Choose Test connection below. Once discovery is verified, choose Add Hermes to connect and save. Open Chat for the saved Agent, select a supported model and send your first message deliberately. Only a reply proves generation; testing does not send a message.';

  @override
  String get connectionGuideNext => 'Next step';

  @override
  String get connectionGuideBack => 'Previous step';

  @override
  String get connectionGuideReady => 'Ready to test';

  @override
  String get connectionGuideDocs => 'Official Agent setup instructions';

  @override
  String get connectionGuideDocsFailed =>
      'Could not open the instructions. Visit hermes-agent.nousresearch.com/docs/user-guide/features/api-server.';

  @override
  String get profileGenerateAvatar => 'Generate avatar';

  @override
  String get profileAvatarUnavailable =>
      'Avatar generation and assignment are unavailable through this Agent API connection. Hermes Desktop has a separate avatar workflow; Wing cannot use it through this API. Your profile is unchanged.';

  @override
  String get connectionCheckAction => 'Test connection';

  @override
  String get connectionCheckCancel => 'Cancel test';

  @override
  String get connectionCheckBoundary =>
      'Tests authenticated discovery only. It does not save a credential, open Chat, send a message or prove model generation.';

  @override
  String get connectionCheckVerified =>
      'Discovery verified. Choose Add Hermes to connect and save; send your first message deliberately in Chat.';

  @override
  String get connectionCheckUnsupported =>
      'Discovery verified, but this Agent did not advertise a supported, authorized chat transport. Chat remains unavailable.';

  @override
  String get connectionCheckDenied =>
      'Authentication rejected. Use the Agent API token for this exact endpoint and profile, not a provider key. Check access permissions before testing again.';

  @override
  String get connectionCheckInvalid =>
      'Use the full Agent HTTP(S) endpoint, including its profile prefix when required. Do not put credentials, queries or fragments in the URL.';

  @override
  String get connectionCheckIncompatible =>
      'The response is not a compatible Hermes Agent discovery document. A healthy port or OpenAI chat endpoint alone is not enough.';

  @override
  String get connectionCheckNetwork =>
      'Discovery could not be verified. Check the running Agent, URL and network, then test again deliberately.';

  @override
  String get connectionCheckBrowserNetwork =>
      'The browser could not verify discovery. Network, certificate, mixed-content or CORS restrictions may hide the cause. This does not prove your token is wrong.';

  @override
  String get connectionCheckTls =>
      'The secure connection could not be verified. Fix the certificate or trusted endpoint; do not disable certificate checks.';

  @override
  String get connectionCheckTimeout =>
      'Discovery timed out. Check Agent availability and retry deliberately; nothing was saved or sent.';

  @override
  String connectionBrowserOrigin(String origin) {
    return 'Wing browser origin: $origin';
  }

  @override
  String get connectionBrowserOriginHelp =>
      'Allow this exact origin in Agent\'s API_SERVER_CORS_ORIGINS. localhost and 127.0.0.1 are different origins. Configuration changes may require an administrator-controlled restart; Wing does not apply them.';

  @override
  String get connectionSetupChecklist =>
      'Before connecting: start the authenticated Agent API, obtain its exact endpoint and profile-bound API token, then test below. For a shared gateway, a named profile may use /p/<profile>; do not append /v1. Wing cannot read Agent secrets or reveal a Hermes vault entry. A vault fills only its connected browser, not every browser window.';

  @override
  String get chatConnectionSaveUnconfirmed =>
      'Connected to Hermes, but saving this connection could not be confirmed. Keep this form open and retry Add Hermes to connect and save again.';

  @override
  String get managedSshGenerateKey => 'Generate SSH key';

  @override
  String get managedSshUseGeneratedKey => 'Use saved Wing key';

  @override
  String get managedSshGenerateKeyConsentTitle =>
      'Create a key on this device?';

  @override
  String get managedSshGenerateKeyConsentBody =>
      'Wing keeps the private key in secure storage on this device. Only its public key is copied. Add that public key to the SSH account on your host. An existing Wing key is reused, never replaced.';

  @override
  String get managedSshGenerateKeyConfirm => 'Create or reuse key';

  @override
  String get managedSshCopyPublicKey => 'Copy public key';

  @override
  String get managedSshPublicKeyCopied => 'Public key copied';

  @override
  String get managedSshGeneratedKeyStorageFailure =>
      'Secure key storage is unavailable. No key was selected. Retry or select your own key file.';

  @override
  String get managedSshGeneratedKeySelected => 'Wing key selected';

  @override
  String get managedSshGeneratingKey => 'Creating SSH key…';

  @override
  String get connectionInformationHelpTitle => 'Connection help';

  @override
  String get connectionInformationCopy => 'Copy instructions';

  @override
  String get connectionInformationCopied =>
      'Public instructions copied. No connection values were included.';

  @override
  String get connectionInformationCopyFailed =>
      'Could not copy the instructions. You can select the help text instead.';

  @override
  String get connectionInformationClose => 'Close';

  @override
  String get connectionInformationHelpText =>
      'LOCAL — THIS DEVICE\nLinux: Wing checks ~/.hermes directory metadata. Another Hermes home is not a Project, current working directory or a binding to the running Agent. Discovery does not prove Agent is installed, running, authenticated or model-ready. Configure and start Agent yourself.\nAndroid: localhost and 127.0.0.1 refer to this phone, not your computer. Prepare Agent in Termux using official documentation for current installation steps and limitations. Automatic installation is unavailable in Wing; a fresh install is not qualified by Wing.\n\nSSH — A NATIVE FORWARD\nHost/IP: use the computer\'s reachable hostname or IP provided by its administrator. SSH username: your account on that computer, not the Agent profile. User-run, non-secret Linux examples are whoami (account), hostname -I (candidate addresses) and ss -ltn (listening TCP ports). Addresses may not be reachable from this device. A listening port does not prove it is SSH: verify the actual SSH listener with the administrator.\nSSH port: 22 is a default, not a guarantee. Enter the actual SSH listener port. Review the host-key fingerprint through a trusted administrator before accepting. Authenticate using your SSH password or selected private key, with its passphrase if required. SSH authentication is separate from Agent authentication. For public-key authentication, have the host administrator add only your public key to that SSH account\'s authorized_keys. Never copy, share or install the private key on the host. These commands describe information lookup only, not setup actions.\nAgent port: 8642 is the default API port, but it is configurable. Enter the API listener port on the SSH host, not the SSH port. Wing forwards that listener; an SSH login does not prove Agent readiness.\n\nREMOTE — DIRECT AGENT API\nAgent URL: obtain the full HTTPS API URL from the host administrator, including the configured port or profile path when required. Do not guess an address from network location. A VPN does not replace Agent authentication.\nAgent API token: use the credential supplied separately through Agent-approved configuration. This is not an SSH password, provider key or dashboard token. Type it into the masked Agent token field. Never place secrets in the clipboard, QR codes, URLs or command arguments.\n\nCONNECTING\nConfigure an authenticated Agent API using official Agent documentation. Local uses http://127.0.0.1:8642 by default; that port is configurable on the host. Linux advanced local endpoint controls can select a different configured API endpoint. Android This phone uses the fixed loopback endpoint. Nothing in this help installs, starts, restarts or configures a service. Only an explicit Add Hermes action checks the connection; finishing guidance is not a connected or model-ready state. These copyable instructions contain no current form values or credentials.';

  @override
  String get platformLocalConnectBody =>
      'Connect directly to Hermes Agent on this device. Preparing Agent and discovering its home are separate from an authenticated connection.';

  @override
  String get platformLocalTokenLabel => 'Agent API token';

  @override
  String get platformLocalTokenHelper =>
      'Agent API authentication is required even on loopback. Enter your API token, not a provider key or SSH password.';

  @override
  String get platformLocalHomeTitle => 'Hermes home';

  @override
  String get platformLocalHomeExplanation =>
      'Wing checks ~/.hermes directory metadata on this device. Choose another Hermes home if needed. No files are read, and this choice is not saved or sent to Agent. A found directory does not prove an installation, running service, authentication or model readiness, or bind the running Agent to that home.';

  @override
  String get platformLocalHomeInspecting => 'Checking default Hermes home…';

  @override
  String get platformLocalHomeFound => 'Directory found — discovery only';

  @override
  String get platformLocalHomeMissing =>
      'Hermes home was not found. Select another directory or prepare Agent separately.';

  @override
  String get platformLocalHomeNotDirectory =>
      'The selected location is not a directory.';

  @override
  String get platformLocalHomeUnreadable =>
      'Could not inspect this directory. Check access or choose another Hermes home.';

  @override
  String get platformLocalHomeUnsupported =>
      'Directory inspection is unavailable on this platform.';

  @override
  String get platformLocalChooseHome => 'Choose another Hermes home';

  @override
  String get platformLocalAdvancedEndpoint => 'Advanced local endpoint';

  @override
  String get platformLocalPhoneTitle => 'This phone';

  @override
  String get platformLocalPhoneSummary =>
      'Run Agent in the separate Termux app, then connect here. Wing cannot install or start it; authentication is still required.';

  @override
  String get platformLocalSetupDetails => 'Set up Termux and Agent';

  @override
  String get platformLocalPhoneBoundary =>
      'Prepare Hermes Agent in Termux yourself, then connect directly. Wing cannot inspect Termux files and does not install, configure, start or restart Agent. Loopback still requires authentication.';

  @override
  String get platformLocalPackageWarning =>
      'Automatic installation is unavailable in Wing. Follow the official Agent Termux documentation for current installation steps and limitations. Fresh installation and persistent background operation are not qualified by Wing. Debian/proot is a separate, unqualified setup path.';

  @override
  String get platformLocalPrepareTitle => '1. Termux and Agent';

  @override
  String get platformLocalPrepareBody =>
      'Install or open Termux using its official guide. For a fresh Agent installation, read the package warning and current official documentation first. If Agent is already installed, check hermes --version and hermes doctor in Termux before continuing.';

  @override
  String get platformLocalTermuxDocs => 'Official Termux installation guide';

  @override
  String get platformLocalAgentDocs => 'Official Agent Termux documentation';

  @override
  String get platformLocalExistingAgent => 'Agent is installed — configure it';

  @override
  String get platformLocalSkipGuide => 'Agent already running — skip guide';

  @override
  String get platformLocalConfigureTitle => '2. Configure and start Agent';

  @override
  String get platformLocalConfigureBody =>
      'In Termux, run hermes setup to configure your provider and model. Follow Agent\'s API documentation to enable API_SERVER_ENABLED=true, set a strong API_SERVER_KEY in Agent-owned configuration, and use API_SERVER_HOST=127.0.0.1 and API_SERVER_PORT=8642. Never put credentials in command arguments or the clipboard. Run hermes gateway in the foreground and keep Termux open. Android may suspend or stop it. Continuing only records your choice; it does not verify readiness.';

  @override
  String get platformLocalApiDocs => 'Official authenticated API setup';

  @override
  String get platformLocalStartedAgent =>
      'I started Agent — continue to connection';

  @override
  String get platformLocalAuthenticateTitle => '3. Connect to Agent';

  @override
  String get platformLocalAuthenticateBody =>
      'Connect to http://127.0.0.1:8642 on this phone. Type the Agent API token into the masked field below, not a provider key or dashboard token. Connection is checked only when you choose Add Hermes; guide completion is not a connected state.';

  @override
  String get platformLocalGuideBack => 'Back to guidance';

  @override
  String get platformLocalDocumentationFailed =>
      'Could not open the official documentation. Try again when a browser is available.';

  @override
  String get platformLocalBrowserExplanation =>
      'This platform cannot inspect the Agent host\'s Hermes home. Use the direct authenticated Agent API below. In a full browser, loopback refers to the browser\'s device; browser transport rules still apply.';

  @override
  String get welcomeEyebrow => 'HERMES WING';

  @override
  String get welcomeTitle => 'Welcome to Hermes Wing';

  @override
  String get welcomeSubtitle =>
      'Your client for Hermes Agent. Connect to your computer or a trusted server.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeLocalHint =>
      'Connect to a running local Hermes Agent. Nothing is installed automatically.';

  @override
  String get welcomeOr => 'or';

  @override
  String get welcomeSsh => 'Connect via SSH';

  @override
  String get managedSshInvalidToken =>
      'Use a bounded access token without spaces or control characters.';

  @override
  String get managedSshPrivateKeyChoice => 'Private key';

  @override
  String get managedSshPasswordChoice => 'Password';

  @override
  String get managedSshSelectKey => 'Select private key';

  @override
  String get managedSshKeyRequired =>
      'Select a private key for this connection attempt.';

  @override
  String get managedSshPassphrase => 'Private-key passphrase';

  @override
  String get managedSshPassphraseRequired =>
      'Enter a passphrase of at most 4096 characters without null characters.';

  @override
  String get managedSshUnlockFailed =>
      'Could not unlock this private key. Check its passphrase or select another key.';

  @override
  String get managedSshKeyUnreadable =>
      'Could not read the selected private key. Select it again.';

  @override
  String get managedSshKeyTooLarge =>
      'The selected private key exceeds 64 KiB.';

  @override
  String get managedSshKeyUnsupportedFormat =>
      'This private-key format is not supported. Select an OpenSSH, RSA or EC private key.';

  @override
  String get managedSshKeyInvalid =>
      'The selected file is not a valid supported SSH private key.';

  @override
  String get managedSshSelectedKey => 'Selected private key';

  @override
  String get managedSshAuthenticationFailed =>
      'SSH authentication was rejected. Check your username and authentication choice, then retry.';

  @override
  String get managedSshHostLabel => 'SSH host';

  @override
  String get managedSshPortLabel => 'SSH port';

  @override
  String get managedSshUsernameLabel => 'Username';

  @override
  String get managedSshPasswordLabel => 'SSH password';

  @override
  String get managedSshAgentPortLabel => 'Hermes Agent port';

  @override
  String get managedSshAgentTokenLabel => 'Agent access token (optional)';

  @override
  String get managedSshConnectAction => 'Connect via SSH';

  @override
  String get managedSshConnectingAction => 'Connecting via SSH…';

  @override
  String get managedSshInvalidHost =>
      'Enter a host name or IP address, not a URL or command.';

  @override
  String get managedSshInvalidPort => 'Enter a port from 1 to 65535.';

  @override
  String get managedSshUsernameRequired => 'Enter your SSH username.';

  @override
  String get managedSshPasswordRequired => 'Enter your SSH password.';

  @override
  String get managedSshHostKeyTitle => 'Verify SSH host';

  @override
  String get managedSshHostKeyBody =>
      'Compare this fingerprint with the host\'s SSH key before trusting it. Wing will remember this host and SSH port securely and block changed keys. Cancel if you cannot verify it.';

  @override
  String get managedSshHostKeyChanged =>
      'The SSH host key differs from the remembered key. Connection blocked. Verify the change with the host administrator; Wing cannot replace a remembered key here.';

  @override
  String get managedSshHostTrustUnavailable =>
      'SSH host trust could not be read or saved securely. Connection blocked. Restore secure storage access before trying again.';

  @override
  String get managedSshTrustAction => 'Trust and remember host';

  @override
  String get managedSshFailed =>
      'Could not establish the SSH connection. Check the host and authentication, then retry.';

  @override
  String get managedSshInterruptedTitle => 'SSH connection interrupted';

  @override
  String get managedSshInterruptedBody =>
      'Retry opens the same SSH target for fresh authentication. Wing retains the selected profile and session, but uncertain work needs Agent readback. Nothing is resent, approved or stopped automatically.';

  @override
  String get managedSshUnsupported =>
      'Managed SSH is not available in this browser. Use Wing on Android or desktop.';

  @override
  String get welcomeRemote => 'Connect to Remote Hermes';

  @override
  String get welcomeStorageRetry =>
      'Saved connections could not be read. Retry';

  @override
  String get profilesSearchLabel => 'Search profiles';

  @override
  String get chatProfileSearch => 'Search profiles by name, ID or model';

  @override
  String get chatProfileManage => 'Manage profiles';

  @override
  String get chatProfileHighlighted => 'Keyboard selection';

  @override
  String get profilesSearchClear => 'Clear profile search';

  @override
  String get profilesSearchHelp =>
      'Search this loaded inventory by profile ID, name, description or model. Search does not change the active chat.';

  @override
  String get profilesSearchNoMatchesTitle => 'No matching profiles';

  @override
  String get profilesSearchNoMatchesBody =>
      'Try another profile ID, name, description or model, or clear the search.';

  @override
  String get chatSessionRestorationPendingTitle =>
      'Restoring your conversation';

  @override
  String get chatSessionRestorationPendingBody =>
      'Opening your remembered conversation. Sending and New Chat are paused so nothing goes to another session.';

  @override
  String get chatSessionRestorationFailedTitle => 'Conversation not restored';

  @override
  String get chatSessionRestorationUnsupportedBody =>
      'This Agent does not support restoring the remembered conversation directly. Retry after its capabilities change, or choose a session.';

  @override
  String get chatSessionRestorationAuthenticationBody =>
      'The Agent did not authorize access to the remembered conversation. Check this connection’s access, then retry or choose a session.';

  @override
  String get chatSessionRestorationUnavailableBody =>
      'The remembered conversation is unavailable. It has not been replaced. Retry, or choose a session.';

  @override
  String get chatSessionRestorationTransientBody =>
      'The remembered conversation could not be reached. It has not been replaced. Retry, or choose a session.';

  @override
  String get chatSessionRestorationIncompatibleBody =>
      'The Agent response could not confirm the remembered conversation. It has not been replaced. Retry, or choose a session.';

  @override
  String get chatSessionRestorationRetry => 'Retry';

  @override
  String get chatSessionRestorationChoose => 'Choose session';

  @override
  String get chatSessionRestorationProfileRequiredBody =>
      'Retry to load this profile’s sessions before choosing a conversation.';

  @override
  String get profileCatalogLoading =>
      'Loading providers and models from Hermes Agent…';

  @override
  String get profileCatalogUnavailable =>
      'The Agent catalog could not be loaded. Retry, or enter a provider and model manually.';

  @override
  String get profileCatalogRetry => 'Retry catalog';

  @override
  String get transcriptLargeMessageScroll =>
      'Large message. Scroll to read all content.';

  @override
  String get chatAttachmentDraftEvicted =>
      'The attachment was released to save memory. Attach it again before sending.';

  @override
  String get chatTranscriptLatestAction => 'Latest activity';

  @override
  String chatTranscriptRevealEarlier(int remaining) {
    return 'Show up to 100 earlier loaded turns ($remaining remaining)';
  }

  @override
  String chatTranscriptContinuedTools(String title) {
    return '$title (continued)';
  }

  @override
  String get chatLiveVoiceTitle => 'Live voice';

  @override
  String get chatLiveVoiceStartAction => 'Start Live voice';

  @override
  String get chatLiveVoiceConsentTitle => 'Start Live voice?';

  @override
  String get chatLiveVoiceConsentBody =>
      'For this session, Wing will keep listening, send recognized turns automatically and speak replies aloud. Speak while a reply plays to interrupt it. Microphone and speech services may process audio on your device or through the connected Agent. Mute the microphone or end at any time. Your saved speech preference will not change. This uses speech recognition and reply playback, not a realtime voice model.';

  @override
  String get chatLiveVoiceUnavailableTitle => 'Live voice unavailable';

  @override
  String get chatLiveVoiceUnavailableBody =>
      'Live voice needs both microphone capture and speech playback. Check Voice & speech settings and device services. You can continue in text or dictate a draft separately.';

  @override
  String get chatLiveVoiceMuteMicrophone => 'Mute microphone';

  @override
  String get chatLiveVoiceUnmuteMicrophone => 'Unmute microphone';

  @override
  String get chatLiveVoiceMicrophoneMuted => 'Microphone muted';

  @override
  String get chatLiveVoiceEndAction => 'End · return to text';

  @override
  String get chatVoiceMuteOutputAction => 'Mute speech';

  @override
  String get chatVoiceUnmuteOutputAction => 'Unmute speech';

  @override
  String get chatVoicePauseMicrophoneAction => 'End hands-free listening';

  @override
  String get chatVoiceEndAction => 'End voice session';

  @override
  String get chatVoiceStopOutputAction => 'Stop reply';

  @override
  String get chatVoiceWaitingLabel => 'Waiting for reply';

  @override
  String get chatVoiceDictateAction => 'Dictate a draft';

  @override
  String get chatVoiceCancelDraftAction => 'Cancel draft dictation';

  @override
  String get chatVoiceDictateHint => 'Review the text before sending';

  @override
  String get chatVoicePausedTitle => 'Voice paused';

  @override
  String get chatVoiceResumeAction => 'Resume hands-free';

  @override
  String get chatVoiceInterruptionLabel => 'Listening for interruption';

  @override
  String get chatVoiceOutputLabel => 'Playing assistant reply';

  @override
  String get profileActiveChat => 'Active chat';

  @override
  String get profileFreshSetupHint =>
      'Choose a provider and model for this new profile.';

  @override
  String get profileCloneSetupHint =>
      'Copies this profile’s configuration. Leave provider and model blank to inherit them.';

  @override
  String chatHostLabel(String host) {
    return 'Host: $host';
  }

  @override
  String chatNamedComposerHint(String profile) {
    return 'Message $profile…';
  }

  @override
  String get managedFilesTitle => 'Files';

  @override
  String get managedFilesExplanation =>
      'Read-only Agent managed files. This locked root is not the terminal working directory or a Hermes Project. Text previews are limited to 64 KiB; folders to 500 entries. Individual downloads up to 8 MiB use a device save picker on Linux and Android.';

  @override
  String get managedDownloadAction => 'Download file';

  @override
  String managedDownloadProgress(int bytes) {
    return 'Retrieved $bytes bytes…';
  }

  @override
  String managedDownloadSaving(int bytes) {
    return 'Retrieved $bytes bytes. Choose a destination; saved bytes will be verified.';
  }

  @override
  String get managedDownloadCancel => 'Cancel download';

  @override
  String get managedDownloadRetry => 'Retry download';

  @override
  String get managedDownloadVerified =>
      'Saved and byte-verified on this device.';

  @override
  String get managedDownloadCancelled =>
      'Download cancelled. No verified save.';

  @override
  String get managedDownloadFailed =>
      'Download failed. Check access, connection and destination, then retry. The limit is 8 MiB.';

  @override
  String get managedDownloadWriteTitle => 'Write to the selected destination?';

  @override
  String get managedDownloadWriteExplanation =>
      'This writes the downloaded bytes and replaces any file at the chosen destination. Cancel to keep it unchanged. An interrupted write may leave a partial file; only byte-verified saves are confirmed.';

  @override
  String get managedDownloadWriteConfirm => 'Write file';

  @override
  String managedFilesOwner(String connection, String profile, String session) {
    return 'Connection: $connection\nProfile: $profile · Conversation: $session';
  }

  @override
  String get managedFilesNoSelection => 'None selected';

  @override
  String get managedFilesEmpty => 'This folder is empty.';

  @override
  String get managedFilesLoading => 'Reading managed files…';

  @override
  String get managedFilesUnavailable =>
      'Files require an authenticated Agent serve connection with an advertised locked managed root. No terminal or Project folder is substituted.';

  @override
  String get managedFilesDenied =>
      'File access denied. Check this Agent connection’s file permissions.';

  @override
  String get managedFilesFailed =>
      'Files could not be read. Check the connection and retry.';

  @override
  String get managedFilesOversized =>
      'This folder, file or response exceeds the preview limits. No partial content is shown.';

  @override
  String get managedFilesBinary =>
      'This file is not supported UTF-8 text. No active content is opened.';

  @override
  String get managedFilesStale =>
      'The connection or conversation changed. Retry to read the current Agent’s managed root.';

  @override
  String get managedFilesParent => 'Parent folder';

  @override
  String get managedFilesBack => 'Back to files';

  @override
  String get managedFilesRefresh => 'Refresh files';

  @override
  String get managedSshAgentProfileLabel => 'Agent profile (optional)';

  @override
  String get managedSshAgentProfileHelp =>
      'Leave blank for the root API. For a shared gateway, enter only the profile ID (for example hermes-wing), not /p/ or a URL. Use that profile’s Agent token. SSH login alone does not authenticate to Agent.';

  @override
  String get managedSshInvalidAgentProfile =>
      'Use 1–64 lowercase letters, numbers, hyphens or underscores, starting with a letter or number.';

  @override
  String get managedSshStorageUnavailable =>
      'Secure connection storage is unavailable. Restore storage access, then retry with fresh credentials.';

  @override
  String get managedSshTimeout =>
      'SSH connection timed out. Check the host, SSH port and network, then enter credentials and retry.';

  @override
  String get managedSshAgentAuthenticationFailed =>
      'Agent access denied. Check token.';

  @override
  String get managedSshAgentIncompatible => 'Incompatible Agent. Check port.';

  @override
  String get managedSshAgentUnavailable =>
      'The selected Agent surface could not be reached. Check Agent availability and port, then enter credentials and retry.';

  @override
  String get managedSshAgentFailed =>
      'Could not connect to the selected Agent surface. Check its settings, then enter credentials and retry.';

  @override
  String get appTitle => 'Hermes Wing';

  @override
  String get hermesDestination => 'Chat';

  @override
  String get agentsDestination => 'Profiles';

  @override
  String get settingsDestination => 'Settings';

  @override
  String get moreDestinations => 'More';

  @override
  String get openMoreDestinations => 'Open more destinations';

  @override
  String get agentsTitle => 'Profiles';

  @override
  String get agentsSubtitle =>
      'Choose a profile to chat, or create one for a different task.';

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
  String get openChatAction => 'Open chat';

  @override
  String get gatewayConnectionRecoveryBody =>
      'Choose another saved gateway above, or return to Chat to reconnect.';

  @override
  String get chatSavedEndpointsLoading => 'Loading saved Hermes gateways';

  @override
  String get chatSavedEndpointEdit => 'Edit saved Agent connection';

  @override
  String get chatSavedEndpointEditBody =>
      'Edit this saved connection only. Saving does not connect or change the active conversation. A changed Agent URL requires its own Agent credential.';

  @override
  String get chatSavedEndpointReplacementKey => 'Replacement Agent credential';

  @override
  String get chatSavedEndpointKeyHelp =>
      'Leave blank to keep the saved credential only while the URL is unchanged. A changed URL needs its own credential. Saved credentials are never shown here.';

  @override
  String get chatSavedEndpointRemoveKey => 'Remove saved Agent credential';

  @override
  String get chatSavedEndpointTest => 'Test connection';

  @override
  String get chatSavedEndpointCancelTest => 'Cancel test';

  @override
  String get chatSavedEndpointTestCancelled =>
      'Test cancelled. No connection was saved or activated.';

  @override
  String get chatSavedEndpointTestSuccess =>
      'Supported Agent discovery responded. No connection was saved or activated. This does not verify chat or inference permissions.';

  @override
  String get chatSavedEndpointTestDenied =>
      'Agent discovery denied this credential. Check the draft and explicitly test again.';

  @override
  String get chatSavedEndpointTestFailed =>
      'Agent discovery could not be verified. Check the URL, network and credential, then explicitly test again.';

  @override
  String get chatSavedEndpointStale =>
      'The connection owner or draft changed. Close this editor and open the saved connection again.';

  @override
  String get chatSavedEndpointSaved =>
      'Saved connection updated. The active conversation is unchanged.';

  @override
  String get chatSavedEndpointSaveFailed =>
      'Could not save this connection. Check the URL and secure storage, then explicitly save again. Another saved host cannot be replaced by this edit.';

  @override
  String get chatSavedEndpointsLoadFailedTitle => 'Saved gateways unavailable';

  @override
  String get chatSavedEndpointsLoadFailedBody =>
      'Hermes Wing could not read saved gateways from secure storage. You can still enter connection details manually.';

  @override
  String get saveAction => 'Save';

  @override
  String get doneAction => 'Done';

  @override
  String get personaLabel => 'Persona';

  @override
  String get personaLoading => 'Loading the authoritative persona';

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
  String get toolsRefreshAction => 'Refresh inventory';

  @override
  String get toolsRefreshFailed => 'Tool inventory could not be refreshed.';

  @override
  String get toolsSubtitle => 'Skills and toolsets available on this gateway.';

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
  String get shellWorkflowNavigation => 'Workflow';

  @override
  String get shellUtilityNavigation => 'Utilities';

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
  String connectionProfileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles',
      one: '1 profile',
    );
    return '$_temp0';
  }

  @override
  String get installedSkillsTitle => 'Installed skills';

  @override
  String get enabledToolsetsTitle => 'Enabled toolsets';

  @override
  String get toolsetsTitle => 'Toolsets';

  @override
  String get searchToolsetsLabel => 'Search toolsets and resolved tools';

  @override
  String get clearToolsetsSearch => 'Clear toolsets search';

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
  String get clearInstalledSkillsSearch => 'Clear installed skills search';

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
  String get schedulesSubtitle => 'Scheduled work for this profile.';

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
  String get schedulesEmptyTitle => 'No schedules yet';

  @override
  String get schedulesEmptyBody =>
      'No scheduled jobs were reported for this profile.';

  @override
  String get schedulesReadOnlyNote =>
      'Read-only schedule inventory. Manage scheduled work on the host.';

  @override
  String get schedulesRefreshTooltip => 'Refresh schedules';

  @override
  String get schedulesRefreshing => 'Refreshing scheduled jobs';

  @override
  String get schedulesSearchLabel => 'Search schedules';

  @override
  String get schedulesFilterLabel => 'Show schedules';

  @override
  String get schedulesFilterAll => 'All';

  @override
  String get schedulesClearFilters => 'Clear filters';

  @override
  String get schedulesNoMatchesTitle => 'No matching schedules';

  @override
  String get schedulesNoMatchesBody =>
      'Try another name, job ID or schedule, or clear the filters.';

  @override
  String get scheduleIdLabel => 'Job ID';

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
  String get gatewayDestination => 'Connections';

  @override
  String get gatewayStatusTitle => 'Connections';

  @override
  String get gatewayChatDisconnected => 'Chat disconnected';

  @override
  String get gatewayChatDisconnectFailed =>
      'Chat could not disconnect. Try again.';

  @override
  String get gatewayChatConnected => 'Chat connected';

  @override
  String get gatewayChatConnectAction => 'Connect chat';

  @override
  String get gatewaySavedConnectionHelp =>
      'Connect chat to use this saved Agent connection. Disconnecting keeps it saved and does not stop Hermes Agent on the host.';

  @override
  String get gatewayStatusSubtitle => 'Host connection and service health.';

  @override
  String get gatewayStatusHelp => 'View status from the selected gateway.';

  @override
  String get gatewayStatusConnectionRequiredBody =>
      'Select a saved Agent connection and choose Connect chat to load Agent status.';

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
      'Read-only gateway status. Manage services, logs, and messaging platforms on the host.';

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
  String get providersSubtitle => 'Choose a model and manage provider access.';

  @override
  String get providersGatewayHelp =>
      'Manage providers and models on the selected gateway.';

  @override
  String get providersLoading => 'Loading providers';

  @override
  String get providersSearchLabel => 'Search providers';

  @override
  String get providersSearchClear => 'Clear provider search';

  @override
  String get providersSearchNoMatchesTitle => 'No matching providers';

  @override
  String get providersSearchNoMatchesBody =>
      'Try another provider name or slug, or clear the search.';

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
  String get providerAuthApiKey => 'API key';

  @override
  String get providerAuthOAuth => 'OAuth sign-in';

  @override
  String get providerAuthOther => 'Provider-managed authentication';

  @override
  String get providerOAuthHostRequired =>
      'Sign in on the Hermes host. This Agent does not advertise remote OAuth setup.';

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
  String get sessionModelSearch => 'Search models or providers';

  @override
  String get sessionModelClearSearch => 'Clear model search';

  @override
  String get sessionModelAllProviders => 'All selectable providers';

  @override
  String get sessionModelResetFilters => 'Reset filters';

  @override
  String get sessionModelNoResults =>
      'No matching selectable models. Clear the search or reset filters.';

  @override
  String get sessionModelCatalogEmpty =>
      'No selectable session models are available from Hermes Agent.';

  @override
  String get sessionModelSelectionUnavailable =>
      'The selected model is no longer available. Choose a model from the current catalog.';

  @override
  String get sessionModelIdentityNotReported =>
      'Hermes Agent does not report this session’s confirmed provider and model. Choose a model explicitly to change this session; cancelling leaves it unchanged.';

  @override
  String get sessionModelChooseExplicitly =>
      'Choose a provider and model from the current catalog.';

  @override
  String sessionModelResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching models',
      one: '1 matching model',
      zero: 'No matching models',
    );
    return '$_temp0';
  }

  @override
  String sessionModelSelected(String provider, String model) {
    return 'Selected: $provider — $model';
  }

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
  String get credentialContractUnavailable =>
      'Credential changes and validation are unavailable for this connection. Manage credentials directly in Hermes Agent.';

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
  String get transcriptExportLoadedNote =>
      'Copy or save all currently loaded turns. Older unfetched history is not included. Files contain the same redacted text as copy, up to 4 MiB; large transcripts may be rejected without truncation.';

  @override
  String get transcriptSaveTextAction => 'Save as text';

  @override
  String get transcriptSaveMarkdownAction => 'Save as Markdown';

  @override
  String get transcriptExportUnsupported =>
      'File export is available in the browser and on Linux only.';

  @override
  String get transcriptExportOwnerChanged =>
      'The conversation changed. Open transcript actions again to export it.';

  @override
  String get transcriptExportDownloadStarted =>
      'Transcript download requested. Check your browser downloads for the file.';

  @override
  String get transcriptExportSaved => 'Transcript saved to the selected file.';

  @override
  String get transcriptExportTooLarge =>
      'This loaded transcript is too large to export (4 MiB limit). No file was written; content was not truncated.';

  @override
  String get transcriptExportFailed =>
      'The transcript could not be exported. No success was confirmed. Try again explicitly.';

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
  String get transcriptCopyFailedMessage =>
      'Could not copy transcript. Try again.';

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
  String get codeCopyFailedMessage => 'Could not copy code. Try again.';

  @override
  String get showMoreAction => 'Show more';

  @override
  String get showLessAction => 'Show less';

  @override
  String get reasoningTitle => 'Reasoning';

  @override
  String get chatReasoningThinking => 'Thinking…';

  @override
  String get chatReasoningThought => 'Thought';

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
  String get localCommandTimestampsDescription =>
      'Toggle timestamp labels in this window. Use on, off, toggle or status; Agent defaults are not synced.';

  @override
  String get localCommandTimestampsUsage =>
      'Usage: /timestamps or /ts [on|off|toggle|status]. Local to this window; Agent defaults are not synced.';

  @override
  String get localCommandTimestampsOn =>
      'Timestamps on in this window. Agent defaults are not synced.';

  @override
  String get localCommandTimestampsOff =>
      'Timestamps off in this window. Agent defaults are not synced.';

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
    String _temp0 = intl.Intl.pluralLogic(
      models,
      locale: localeName,
      other: '$models models',
      one: '1 model',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skills,
      locale: localeName,
      other: '$skills skills',
      one: '1 skill',
    );
    String _temp2 = intl.Intl.pluralLogic(
      toolsets,
      locale: localeName,
      other: '$toolsets toolsets',
      one: '1 toolset',
    );
    String _temp3 = intl.Intl.pluralLogic(
      jobs,
      locale: localeName,
      other: '$jobs jobs',
      one: '1 job',
    );
    return '$_temp0 • $_temp1 • $_temp2 • $_temp3';
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
  String get diagnosticsCopyInProgress => 'Copying diagnostics';

  @override
  String get diagnosticsCopySubtitle =>
      'Safe snapshot; excludes secrets, raw logs, transcripts, and local paths.';

  @override
  String get diagnosticsCopiedNotice => 'Hermes diagnostics copied';

  @override
  String get diagnosticsCopyFailedNotice =>
      'Could not copy diagnostics. Try again.';

  @override
  String get voiceSettingsTitle => 'Voice & speech';

  @override
  String get voiceBehaviorSection => 'Voice behavior';

  @override
  String get voiceContinuousTitle => 'Continuous voice';

  @override
  String get voiceContinuousSubtitle =>
      'Send recognized speech to Hermes automatically.';

  @override
  String get voiceSpeakRepliesTitle => 'Speak replies aloud';

  @override
  String get voiceSpeakRepliesSubtitle =>
      'Read replies aloud when hands-free voice is on.';

  @override
  String get voiceCompletionSoundTitle => 'Response completion sound';

  @override
  String get voiceCompletionSoundSubtitle =>
      'Play a sound when a reply finishes.';

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
  String get settingsScanPairingQr => 'Connect directly to Hermes Agent.';

  @override
  String get settingsCredentialsNote =>
      'Credentials stay in secure storage; values hidden';

  @override
  String get settingsVoiceSummary => 'Voice input, spoken replies, and sounds';

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
  String get settingsReconnectAction => 'Refresh status';

  @override
  String get settingsConnectGatewayError =>
      'Could not connect to this gateway.';

  @override
  String get settingsReconnectGatewayError => 'Could not refresh host status.';

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
  String get enrollIntro =>
      'Connect directly to an existing Hermes Agent using Local, SSH, or Remote.';

  @override
  String get enrollOptionalSetupAction => 'Local setup';

  @override
  String get enrollPhoneHelp =>
      'Manual setup in Termux. Readiness is not verified.';

  @override
  String get enrollBackToOptions => 'Connection options';

  @override
  String get enrollLinuxHelp =>
      'Inspect Hermes-home directory metadata and connect directly to Agent. Prepare and start Agent separately; discovery does not prove readiness.';

  @override
  String get enrollTitle => 'Connect to Hermes';

  @override
  String get enrollLegacyHandoffTitle =>
      'Pairing links are no longer supported';

  @override
  String get enrollLegacyHandoffBody =>
      'This old link or shared text was discarded. Connect directly to Hermes Agent using Local, SSH or Remote. On Android, use SSH, Remote or the on-phone Termux guide. Existing saved connections are unchanged.';

  @override
  String get closeAction => 'Close';

  @override
  String get chatWorkspaceTabsLabel => 'Open conversations';

  @override
  String chatWorkspaceTabLabel(String title, String profile, String host) {
    return 'Open $title · $profile · $host';
  }

  @override
  String chatWorkspaceCloseTitle(String title) {
    return 'Close $title';
  }

  @override
  String get chatWorkspaceKeepOpen => 'Keep open';

  @override
  String get chatWorkspaceStopClose => 'Stop and close';

  @override
  String get chatWorkspaceStopCloseBody =>
      'This conversation has active work. Stop only this run and close its tab after Hermes confirms the outcome. The session and other conversations are not deleted.';

  @override
  String get chatWorkspaceStopUnavailable =>
      'Stop is unavailable for this conversation on the current Agent transport. The tab stays open; closing a view would not confirm that Agent work stopped.';

  @override
  String get chatWorkspaceCloseUncertain =>
      'Stop is not confirmed. This tab stays open. Reconnect to reconcile Agent run status and history before closing; do not resend the prompt.';

  @override
  String get chatWorkspaceReopenBody =>
      'Open this exact conversation before closing it so Hermes can confirm its current run state. Switching hosts or profiles closes local streams, not Agent work.';

  @override
  String get chatWorkspaceOpenFailed =>
      'This conversation could not be opened. Its owner and draft are unchanged. Reconnect to its saved host and profile, then try again.';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String routeNotFound(String path) {
    return 'Hermes Wing does not have a screen for $path.';
  }

  @override
  String get routeNotFoundAction => 'Return to chat';

  @override
  String get soulConnectionRequiredTitle => 'Connect to edit a persona';

  @override
  String get soulConnectionRequiredBody =>
      'Open a saved gateway chat before editing its selected profile persona.';

  @override
  String get soulOpenChatAction => 'Open chat';

  @override
  String get soulProfileRequiredTitle => 'Choose a profile';

  @override
  String get soulProfileRequiredBody =>
      'Select a profile before opening its persona editor.';

  @override
  String get soulOpenProfilesAction => 'Open profiles';

  @override
  String get soulUnavailableTitle => 'Persona editing unavailable';

  @override
  String get soulUnavailableBody =>
      'This gateway did not advertise scoped SOUL read and write operations for the selected profile.';

  @override
  String get agentsGatewayPickerHelp =>
      'Add and edit profiles on the selected gateway.';

  @override
  String get gatewayContactsEmptyTitle => 'Add your first Hermes profile';

  @override
  String get gatewayContactsEmptyBody =>
      'Connect a gateway to see its profiles and start a conversation.';

  @override
  String get gatewayContactsConnectAction => 'Add Hermes';

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
    return 'The endpoint $endpoint uses plain HTTP. Continue only on a trusted NetBird or Tailscale network, another trusted VPN, or an isolated LAN. Prefer HTTPS for remote Hermes endpoints.';
  }

  @override
  String get chatConnectionContinueAction => 'Continue';

  @override
  String get chatConnectionDisconnectTitle => 'Disconnect from Hermes?';

  @override
  String chatConnectionDisconnectBody(String target) {
    return 'Disconnect chat from $target? Your saved connection stays on this device, so you can reconnect. Hermes Agent keeps running on the host.';
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
  String get chatUnsupportedAgentTitle => 'Update Hermes Wing or Hermes Agent';

  @override
  String get chatUnsupportedAgentBody =>
      'This Hermes Agent uses a capability format that this version of Hermes Wing cannot safely operate. Update Hermes Wing or Hermes Agent, then reconnect.';

  @override
  String get chatTranscriptLoadEarlierAction => 'Load earlier messages';

  @override
  String get chatTranscriptLoadingEarlierLabel => 'Loading earlier messages…';

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
  String get chatErrorConnectInvalidEndpointTitle =>
      'Check the Hermes address.';

  @override
  String get chatErrorConnectInvalidEndpointBody =>
      'Enter a complete HTTP or HTTPS Hermes Agent URL, then try again.';

  @override
  String get chatErrorConnectIncompatibleTitle =>
      'Hermes returned an unsupported response.';

  @override
  String get chatErrorConnectIncompatibleBody =>
      'Update Hermes Wing or Hermes Agent, verify the address points to Hermes Agent, then reconnect.';

  @override
  String get chatErrorConnectTlsTitle => 'Secure connection to Hermes failed.';

  @override
  String get chatErrorConnectTlsBody =>
      'Check the HTTPS certificate or trusted host identity. If the identity changed, verify it through a trusted administrator before reconnecting.';

  @override
  String get chatErrorConnectTimeoutTitle => 'Hermes did not respond in time.';

  @override
  String get chatErrorConnectTimeoutBody =>
      'Check that Hermes Agent is running and reachable, then try again.';

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
      'Connect directly to Hermes Agent. Choose how this device can reach it.';

  @override
  String get chatLayoutConnectionModeLabel => 'Connection method';

  @override
  String get chatLayoutConnectionModeLocalLabel => 'Local';

  @override
  String get chatLayoutConnectionPrimaryRemoteLabel => 'Remote';

  @override
  String get chatLayoutConnectionModeRemoteLabel => 'Remote HTTPS';

  @override
  String get chatLayoutConnectionModeVpnLabel => 'VPN / NetBird / Tailscale';

  @override
  String get chatLayoutConnectionModeSshLabel => 'SSH';

  @override
  String get chatLayoutConnectionModeLocalBody =>
      'Use a local Agent URL, or install Hermes on this device when local setup is available.';

  @override
  String get chatLayoutConnectionModeRemoteBody =>
      'Use an HTTPS Agent URL. Wing currently uses HTTPS/SSE; authenticated WebSocket support waits for an exact Hermes contract.';

  @override
  String get chatLayoutRemoteAuthExplanation =>
      'Connect directly to a Hermes Agent endpoint with its Agent access token. A host-management token or provider API key is not an Agent access token.\n\nBrowser OAuth sign-in is not supported in Wing. An OAuth-only server cannot currently connect through this flow. If access is denied, check the endpoint and its Agent token with the server administrator, then retry explicitly or cancel. A denial does not identify the server\'s sign-in method.';

  @override
  String get chatLayoutConnectionModeVpnBody =>
      'Use the Agent URL reachable through your trusted encrypted NetBird or Tailscale network, or another trusted VPN. Prefer HTTPS; non-local HTTP requires explicit confirmation. Wing does not treat network location as authorization.';

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
      'Enter the Agent URL reachable through your trusted encrypted NetBird or Tailscale network, or another trusted VPN.';

  @override
  String get chatLayoutConnectionModeSshUrlHelper =>
      'Start the fixed tunnel outside Wing, then enter the local Agent URL it exposes.';

  @override
  String get chatLayoutVpsConnectionTitle => 'Hermes Agent connection';

  @override
  String get chatLayoutVpsConnectionBody =>
      'Use an HTTPS or trusted private-network URL. Never expose an unauthenticated Hermes port to the internet.';

  @override
  String get chatLayoutScanQrAction => 'Pairing links are no longer supported';

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
      'Saving a connection uses secure device storage. Connecting alone does not confirm that your token was saved.';

  @override
  String get chatLayoutCredentialBoundaryTitle => 'Agent credential only';

  @override
  String get chatLayoutCredentialBoundaryBody =>
      'This token is only for Hermes Agent access. SSH authentication and provider credentials are separate.';

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
  String get chatComposerModelPickerTooltip => 'Choose model';

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
  String get chatAttachmentPicking => 'Opening the attachment picker';

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
      'Hermes Wing stopped voice when it left the foreground. The microphone is off. Resume when you’re ready.';

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
  String get chatShellConnectAnotherGatewayTooltip => 'Add Hermes';

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
  String get chatStatusCopySurfaceReadinessFailedBody =>
      'Could not copy Hermes surface readiness summary. Try again.';

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
      'Hermes sent this approval without a run or approval id, so it cannot be answered.';

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
  String get chatStatusCommandTruncatedBody =>
      'Command preview truncated for mobile review.';

  @override
  String chatStatusCommandLabel(String value) {
    return 'Command: $value';
  }

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
      'Decision buttons are disabled because Hermes did not include a run or approval id.';

  @override
  String get chatStatusCopiedApprovalDetailsBody =>
      'Copied redacted Hermes approval details.';

  @override
  String get chatStatusCopyDetailsAction => 'Copy details';

  @override
  String get chatRailSessionsTitle => 'Sessions';

  @override
  String get shellLoadedSessions => 'Loaded sessions';

  @override
  String get shellSessionScope => 'Open or create. Manage sessions in Chat.';

  @override
  String shellSessionSource(String source) {
    return 'Source: $source';
  }

  @override
  String get shellNewSession => 'New Session';

  @override
  String get shellSessionPending => 'Opening session…';

  @override
  String get shellSessionFailed =>
      'Could not open the session. Try again in Chat.';

  @override
  String shellOpenSession(String title) {
    return 'Open $title';
  }

  @override
  String get chatRailPinnedGroupLabel => 'Pinned';

  @override
  String get chatRailChatsGroupLabel => 'Chats';

  @override
  String get chatRailPinSessionAction => 'Pin';

  @override
  String get chatRailUnpinSessionAction => 'Unpin';

  @override
  String get chatRailHermesSessionsTitle => 'Hermes sessions';

  @override
  String get chatRailNewSessionAction => 'New';

  @override
  String get chatRailLoadMoreSessionsAction => 'Load more sessions';

  @override
  String get chatRailLoadingMoreSessionsAction => 'Loading more sessions…';

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
  String get chatRailEmptyStateTitle => 'What are we working on?';

  @override
  String get chatRailEmptyStateBody =>
      'Ask Hermes a question, or start with one of these.';

  @override
  String get chatRailPromptSummarizeHelpLabel => 'What can you help me do?';

  @override
  String get chatRailPromptListSkillsLabel => 'Show my available skills';

  @override
  String get chatRailPromptPlanTaskLabel => 'Plan my next coding task';

  @override
  String get chatRailPromptExplainSessionLabel => 'Catch me up on this session';

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
  String get chatRailCopySessionIdAction => 'Copy session ID';

  @override
  String get chatRailCopiedSessionIdBody => 'Copied session ID.';

  @override
  String get chatRailCopySessionIdFailedBody =>
      'Could not copy session ID. Try again.';

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
  String get chatRailCopySessionDetailsFailedBody =>
      'Could not copy session details. Please try again.';

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
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsSearchNoResults => 'No matching settings';

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
  String get themePaletteLabel => 'Accent color';

  @override
  String get settingsThemeHeading => 'Theme';

  @override
  String get avatarGalleryTitle => 'Wing avatars';

  @override
  String get avatarGalleryDescription =>
      'Winged characters generated on this device. Choose a family for this installation; Agent profile avatars stay unchanged.';

  @override
  String avatarVariationLabel(int number) {
    return 'Avatar family $number';
  }

  @override
  String get avatarSaveFailed =>
      'The avatar family is applied for now, but could not be saved on this device.';

  @override
  String get settingsTypographyHeading => 'Typography';

  @override
  String get chatTextScaleTitle => 'Chat text size';

  @override
  String get chatTextScaleDescription =>
      'Adjust conversation text without changing the rest of the interface.';

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
      'Chat, Profiles, and Connections are below. Schedules, Providers, Tools, Persona, and Settings live under More.';

  @override
  String get tipVoice =>
      'Tap the microphone to talk. Hold it to dictate and review before sending.';

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
  String get localSetupAction => 'Use this computer (Local)';

  @override
  String get termuxCopyFailedMessage =>
      'The setup command could not be copied. Select the command and copy it manually.';

  @override
  String get enrollInstallOnPhoneAction => 'Use this phone (Termux)';
}
