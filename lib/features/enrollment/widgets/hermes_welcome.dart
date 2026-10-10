import 'package:flutter/material.dart';
import '../../hermes_chat/screens/hermes_chat_screen.dart';
import '../../../l10n/app_localizations.dart';

/// Desktop's settled onboarding hierarchy, without a motion-dependent reveal.
class HermesWelcome extends StatelessWidget {
  const HermesWelcome({
    required this.onConnect,
    required this.optionalSetup,
    super.key,
  });

  final ValueChanged<HermesConnectionMode> onConnect;
  final Widget optionalSetup;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('hermes-welcome'),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 96).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Image.asset(
                        'assets/branding/hermes-emblem.png',
                        width: 100,
                        height: 82,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s.welcomeEyebrow,
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 3,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        s.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      key: const ValueKey('hermes-enrollment-direct-connect'),
                      onPressed: () => onConnect(HermesConnectionMode.local),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(s.welcomeGetStarted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.welcomeLocalHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(s.welcomeOr),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          key: const ValueKey('hermes-welcome-ssh'),
                          onPressed: () => onConnect(HermesConnectionMode.ssh),
                          icon: const Icon(Icons.key_outlined),
                          label: Text(s.welcomeSsh),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey('hermes-welcome-remote'),
                          onPressed: () =>
                              onConnect(HermesConnectionMode.remote),
                          icon: const Icon(Icons.public),
                          label: Text(s.welcomeRemote),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    optionalSetup,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
