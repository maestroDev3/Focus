import 'package:flutter/material.dart';

import '../domain/background_style.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'background_text.dart';
import 'widgets/focus_background.dart';

/// Lets the user pick the living background from small live previews; the
/// choice applies to all main screens right away (#316).
class BackgroundScreen extends StatefulWidget {
  const BackgroundScreen({super.key, required this.settings, this.onChanged});

  final SettingsRepository settings;

  /// Called with the new style after it was saved.
  final ValueChanged<BackgroundStyle>? onChanged;

  @override
  State<BackgroundScreen> createState() => _BackgroundScreenState();
}

class _BackgroundScreenState extends State<BackgroundScreen> {
  BackgroundStyle? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final style = await widget.settings.loadBackground();
    if (mounted) setState(() => _selected = style);
  }

  Future<void> _select(BackgroundStyle style) async {
    setState(() => _selected = style);
    await widget.settings.saveBackground(style);
    widget.onChanged?.call(style);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.background)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.52,
        ),
        itemCount: BackgroundStyle.values.length,
        itemBuilder: (context, index) {
          final style = BackgroundStyle.values[index];
          return _Preview(
            style: style,
            name: backgroundName(l10n, style),
            selected: style == _selected,
            onTap: () => _select(style),
          );
        },
      ),
    );
  }
}

/// One live preview card with the style's name; a champagne frame and check
/// mark the current choice.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.style,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final BackgroundStyle style;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackgroundChoice(
                    style: style,
                    child: const FocusBackground(child: SizedBox.expand()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
                if (selected)
                  Icon(
                    Icons.check,
                    key: Key('background-${style.name}-selected'),
                    size: 18,
                    color: colors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
