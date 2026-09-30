import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Explains why Focus needs an Android permission before sending the user
/// to the system settings where it is granted.
class PermissionOnboardingScreen extends StatelessWidget {
  const PermissionOnboardingScreen({
    super.key,
    required this.title,
    required this.body,
    required this.onOpenSettings,
  });

  final String title;
  final String body;
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
              Text(title, style: theme.textTheme.displaySmall),
              const SizedBox(height: 16),
              Text(
                body,
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
