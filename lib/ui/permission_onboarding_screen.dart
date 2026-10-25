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
    required this.onOpenAppInfo,
    this.consentLabel,
  });

  final String title;
  final String body;
  final VoidCallback onOpenSettings;

  /// Opens Focus' app info, the way out when Android greys out the switch.
  final VoidCallback onOpenAppInfo;

  /// When set, the main button asks for consent with this label and a
  /// “Not now” button leaves – the prominent disclosure Google Play requires
  /// for the accessibility service.
  final String? consentLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      // Scrolls on small screens and with large fonts; the buttons still sit
      // at the bottom when there is room.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity),
              ),
              child: IntrinsicHeight(
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
              Text(
                l10n.restrictedSettingsHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onOpenAppInfo,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(l10n.openAppInfo),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onOpenSettings,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                ),
                child: Text(consentLabel ?? l10n.openSettings),
              ),
              if (consentLabel != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.notNow),
                ),
              ],
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
