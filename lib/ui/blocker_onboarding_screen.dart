import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Explains why Focus needs the accessibility permission before sending the
/// user to the system settings.
class BlockerOnboardingScreen extends StatelessWidget {
  const BlockerOnboardingScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.blockerOnboardingTitle,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.blockerOnboardingBody,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onOpenSettings,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                ),
                child: Text(l10n.openSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
